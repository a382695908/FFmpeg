/*
 * buffered file I/O
 * Copyright (c) 2001 Fabrice Bellard
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 *
 * Приспособлено из file.c для чтения из обычного файла, в который одновременно
 * с чтением производится запись.
 *
 * Modified by Nikolay Morev on 22.08.13.
 * Copyright (c) 2013 DENIVIP Media. All rights reserved.
 *
 */

#include "libavutil/avstring.h"
#include "libavutil/opt.h"
#include "avformat.h"
#include <fcntl.h>
#if HAVE_IO_H
#include <io.h>
#endif
#if HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <sys/stat.h>
#include <stdlib.h>
#include "os_support.h"
#include "url.h"

/* Some systems may not have S_ISFIFO */
#ifndef S_ISFIFO
#  ifdef S_IFIFO
#    define S_ISFIFO(m) (((m) & S_IFMT) == S_IFIFO)
#  else
#    define S_ISFIFO(m) 0
#  endif
#endif

/* standard file protocol */

typedef struct FileContext {
    const AVClass *class;
    int fd;
    int trunc;
    AVIOInterruptCB eof_callback;
} FileContext;
void pipelike_set_eof_callback(URLContext *h, AVIOInterruptCB eof_callback);

static const AVOption file_options[] = {
    { "truncate", "Truncate existing files on write", offsetof(FileContext, trunc), AV_OPT_TYPE_INT, { .i64 = 1 }, 0, 1, AV_OPT_FLAG_ENCODING_PARAM },
    { NULL }
};

static const AVClass file_class = {
    .class_name = "pipelike",
    .item_name  = av_default_item_name,
    .option     = file_options,
    .version    = LIBAVUTIL_VERSION_INT,
};

static int file_read(URLContext *h, unsigned char *buf, int size)
{
    FileContext *c = h->priv_data;

    int r = read(c->fd, buf, size);
    if (r == 0 && ! ff_check_interrupt(&c->eof_callback)) {
        // При достижении конца файла не прекращаем чтение, а ждем, пока данные не
        // появятся.
        
        return AVERROR(EAGAIN);
    }
    
    return (-1 == r)?AVERROR(errno):r;
}

static int file_get_handle(URLContext *h)
{
    FileContext *c = h->priv_data;
    return c->fd;
}

#if CONFIG_PIPELIKE_PROTOCOL

static int file_open(URLContext *h, const char *filename, int flags)
{
    FileContext *c = h->priv_data;
    int access;
    int fd;
    struct stat st;

    av_strstart(filename, "pipelike:", &filename);

    access = O_RDONLY;
#ifdef O_BINARY
    access |= O_BINARY;
#endif
    do {
        if (fd == -1 && errno == ENOENT) {
            // Небольшая пауза перед повторной попыткой.
            usleep(100000);
        }

        fd = open(filename, access, 0666);

        // Файл может еще не появиться на диске в момент начала чтения, поэтому
        // повторяем попытку открыть.
    } while (fd == -1 && errno == ENOENT &&
             ! ff_check_interrupt(&h->interrupt_callback) &&
             ! ff_check_interrupt(&c->eof_callback));

    if (fd == -1)
        return AVERROR(errno);
    c->fd = fd;

    h->is_streamed = 1;

    return 0;
}

/* XXX: use llseek */
static int64_t file_seek(URLContext *h, int64_t pos, int whence)
{
    FileContext *c = h->priv_data;
    off_t ret;

    if (whence == AVSEEK_SIZE) {
        struct stat st;
        ret = fstat(c->fd, &st);
        return ret < 0 ? AVERROR(errno) : (S_ISFIFO(st.st_mode) ? 0 : st.st_size);
    }

    ret = lseek(c->fd, pos, whence);

    return ret < 0 ? AVERROR(errno) : ret;
}

static int file_close(URLContext *h)
{
    FileContext *c = h->priv_data;
    return close(c->fd);
}

void pipelike_set_eof_callback(URLContext *h, AVIOInterruptCB eof_callback)
{
    FileContext *c = h->priv_data;
    c->eof_callback = eof_callback;
}

URLProtocol ff_pipelike_protocol = {
    .name                = "pipelike",
    .url_open            = file_open,
    .url_read            = file_read,
    .url_write           = NULL,
    .url_seek            = file_seek,
    .url_close           = file_close,
    .url_get_file_handle = file_get_handle,
    .url_check           = NULL,
    .priv_data_size      = sizeof(FileContext),
    .priv_data_class     = &file_class,
};

#endif /* CONFIG_PIPELIKE_PROTOCOL */
