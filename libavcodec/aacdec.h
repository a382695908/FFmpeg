
/*
 Это модуль aacdec.c, вырезанный из ffmpeg.
 
 Изменения по сравнению с исходной версией:
 - добавлена сокращенная версия aac_decode_frame_int, которой достаточно для определения длины пакета.
 */

#include "libavcodec/aac.h"

#define DVERROR_INVALID_PACKET (-666)

int aac_decode_frame_int2(AVCodecContext *avctx, GetBitContext *gb);
