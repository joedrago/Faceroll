#ifdef _WIN32
// Windows
#define _CRT_SECURE_NO_WARNINGS 1
#include <fcntl.h>
#include <io.h>
#ifdef WABITS_LUA
#include "wabits_lua.h"
#include <windows.h>
#else
#include <winsock.h>
#endif

#else
// MacOS
#include <arpa/inet.h>
#include <sys/socket.h>
typedef int SOCKET;
#endif

#include <assert.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Most of the wabits*() functions and constants are repurposed from my libavif
// y4m.c implementation. Anything bugfixes in there are still under the same
// license as libavif, so I'll drop this clause here just to keep it honest:
//
// Copyright 2019 Joe Drago. All rights reserved.
// SPDX-License-Identifier: BSD-2-Clause
//
// If anything I'm borrowing BSD code from myself, heh.

typedef int wabitsBool;
#define WABITS_TRUE 1
#define WABITS_FALSE 0

#define WABITS_MIN(a, b) (((a) < (b)) ? (a) : (b))
#define WABITS_DATA_EMPTY { NULL, 0 }

typedef enum wabitsChannelIndex
{
    WABITS_CHAN_Y = 0,
    WABITS_CHAN_U = 1,
    WABITS_CHAN_V = 2,
    WABITS_CHAN_A = 3
} wabitsChannelIndex;

typedef struct wabitsRWData
{
    uint8_t * data;
    size_t size;
} wabitsRWData;

typedef enum wabitsPixelFormat
{
    WABITS_PIXEL_FORMAT_NONE = 0,
    WABITS_PIXEL_FORMAT_YUV444,
    WABITS_PIXEL_FORMAT_YUV422,
    WABITS_PIXEL_FORMAT_YUV420,
    WABITS_PIXEL_FORMAT_YUV400,
    WABITS_PIXEL_FORMAT_COUNT
} wabitsPixelFormat;

void wabitsRWDataFree(wabitsRWData * raw)
{
    free(raw->data);
    raw->data = NULL;
    raw->size = 0;
}

void wabitsRWDataRealloc(wabitsRWData * raw, size_t newSize)
{
    if (raw->size != newSize) {
        uint8_t * newData = (uint8_t *)malloc(newSize);
        if (raw->size && newSize) {
            memcpy(newData, raw->data, WABITS_MIN(raw->size, newSize));
        }
        free(raw->data);
        raw->data = newData;
        raw->size = newSize;
    }
}

void wabitsRWDataSet(wabitsRWData * raw, const uint8_t * data, size_t len)
{
    if (len) {
        wabitsRWDataRealloc(raw, len);
        memcpy(raw->data, data, len);
    } else {
        wabitsRWDataFree(raw);
    }
}

#define Y4M_MAX_LINE_SIZE 2048

struct y4mFrameIterator
{
    int width;
    int height;
    int depth;
    wabitsPixelFormat format;
    FILE * inputFile;
    const char * displayFilename;
};

static wabitsBool getHeaderString(uint8_t * p, uint8_t * end, char * out, size_t maxChars)
{
    uint8_t * headerEnd = p;
    while ((*headerEnd != ' ') && (*headerEnd != '\n')) {
        if (headerEnd >= end) {
            return WABITS_FALSE;
        }
        ++headerEnd;
    }
    size_t formatLen = headerEnd - p;
    if (formatLen > maxChars) {
        return WABITS_FALSE;
    }

    strncpy(out, (const char *)p, formatLen);
    out[formatLen] = 0;
    return WABITS_TRUE;
}

// Returns an unsigned integer value parsed from [start:end[.
// Returns -1 in case of failure.
static int y4mReadUnsignedInt(const char * start, const char * end)
{
    const char * p = start;
    int64_t value = 0;
    while (p < end && *p >= '0' && *p <= '9') {
        value = value * 10 + (*(p++) - '0');
        if (value > INT_MAX) {
            return -1;
        }
    }
    return (p == start) ? -1 : (int)value;
}

static wabitsBool y4mColorSpaceParse(const char * formatString, struct y4mFrameIterator * frame)
{
    if (!strcmp(formatString, "C420jpeg")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        // Chroma sample position is center.
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420mpeg2")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420paldv")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444p10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C422p10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV422;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420p10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444p12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C422p12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV422;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420p12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C444alpha")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV444;
        frame->depth = 8;
        // frame->hasAlpha = WABITS_TRUE;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C422")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV422;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "C420")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV420;
        frame->depth = 8;
        // Chroma sample position is center.
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "Cmono")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV400;
        frame->depth = 8;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "Cmono10")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV400;
        frame->depth = 10;
        return WABITS_TRUE;
    }
    if (!strcmp(formatString, "Cmono12")) {
        frame->format = WABITS_PIXEL_FORMAT_YUV400;
        frame->depth = 12;
        return WABITS_TRUE;
    }
    return WABITS_FALSE;
}

static int y4mReadLine(FILE * inputFile, wabitsRWData * raw, const char * displayFilename)
{
    static const int maxBytes = Y4M_MAX_LINE_SIZE;
    int bytesRead = 0;
    uint8_t * front = raw->data;

    for (;;) {
        if (fread(front, 1, 1, inputFile) != 1) {
            fprintf(stderr, "Failed to read line: %s\n", displayFilename);
            break;
        }

        ++bytesRead;
        if (bytesRead >= maxBytes) {
            break;
        }

        if (*front == '\n') {
            return bytesRead;
        }
        ++front;
    }
    return -1;
}

struct Image
{
    int width;
    int height;
    uint8_t * planes[3];
};

#define ADVANCE(BYTES)    \
    do {                  \
        p += BYTES;       \
        if (p >= end)     \
            goto cleanup; \
    } while (0)

wabitsBool y4mRead(FILE * inputFile, struct Image * image, struct y4mFrameIterator ** iter)
{
    wabitsBool result = WABITS_FALSE;

    struct y4mFrameIterator frame;
    frame.width = -1;
    frame.height = -1;
    // Default to the color space "C420" to match the defaults of aomenc and ffmpeg.
    frame.depth = 8;
    frame.format = WABITS_PIXEL_FORMAT_YUV420;
    frame.inputFile = NULL;

    wabitsRWData raw = WABITS_DATA_EMPTY;
    wabitsRWDataRealloc(&raw, Y4M_MAX_LINE_SIZE);

    if (iter && *iter) {
        // Continue reading FRAMEs from this y4m stream
        frame = **iter;
    } else {
        // Open a fresh y4m and read its header
        frame.inputFile = inputFile;
        frame.displayFilename = "(ffmpeg)";

        int headerBytes = y4mReadLine(frame.inputFile, &raw, frame.displayFilename);
        if (headerBytes < 0) {
            fprintf(stderr, "Y4M header too large: %s\n", frame.displayFilename);
            goto cleanup;
        }
        if (headerBytes < 10) {
            fprintf(stderr, "Y4M header too small: %s\n", frame.displayFilename);
            goto cleanup;
        }

        uint8_t * end = raw.data + headerBytes;
        uint8_t * p = raw.data;

        if (memcmp(p, "YUV4MPEG2 ", 10) != 0) {
            fprintf(stderr, "Not a y4m file: %s\n", frame.displayFilename);
            goto cleanup;
        }
        ADVANCE(10); // skip past header

        char tmpBuffer[32];

        while (p != end) {
            switch (*p) {
                case 'W': // width
                    frame.width = y4mReadUnsignedInt((const char *)p + 1, (const char *)end);
                    break;
                case 'H': // height
                    frame.height = y4mReadUnsignedInt((const char *)p + 1, (const char *)end);
                    break;
                case 'C': // color space
                    if (!getHeaderString(p, end, tmpBuffer, 31)) {
                        fprintf(stderr, "Bad y4m header: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    printf("colorspace: %s\n", tmpBuffer);
                    if (!y4mColorSpaceParse(tmpBuffer, &frame)) {
                        fprintf(stderr, "Unsupported y4m pixel format: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    break;
                case 'F': // framerate
                    if (!getHeaderString(p, end, tmpBuffer, 31)) {
                        fprintf(stderr, "Bad y4m header: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    break;
                case 'X':
                    if (!getHeaderString(p, end, tmpBuffer, 31)) {
                        fprintf(stderr, "Bad y4m header: %s\n", frame.displayFilename);
                        goto cleanup;
                    }
                    break;
                default:
                    break;
            }

            // Advance past header section
            while ((*p != '\n') && (*p != ' ')) {
                ADVANCE(1);
            }
            if (*p == '\n') {
                // Done with y4m header
                break;
            }

            ADVANCE(1);
        }

        if (*p != '\n') {
            fprintf(stderr, "Truncated y4m header (no newline): %s\n", frame.displayFilename);
            goto cleanup;
        }
    }

    int frameHeaderBytes = y4mReadLine(frame.inputFile, &raw, frame.displayFilename);
    if (frameHeaderBytes < 0) {
        fprintf(stderr, "Y4M frame header too large: %s\n", frame.displayFilename);
        goto cleanup;
    }
    if (frameHeaderBytes < 6) {
        fprintf(stderr, "Y4M frame header too small: %s\n", frame.displayFilename);
        goto cleanup;
    }
    if (memcmp(raw.data, "FRAME", 5) != 0) {
        fprintf(stderr, "Truncated y4m (no frame): %s\n", frame.displayFilename);
        goto cleanup;
    }

    if ((frame.width < 1) || (frame.height < 1) || ((frame.depth != 8) && (frame.depth != 10) && (frame.depth != 12))) {
        fprintf(stderr, "Failed to parse y4m header (not enough information): %s\n", frame.displayFilename);
        goto cleanup;
    }

    // lazy AF
    assert(frame.width <= 256);
    assert(frame.height <= 256);
    assert(frame.format == WABITS_PIXEL_FORMAT_YUV422);

    image->width = frame.width;
    image->height = frame.height;

    for (int plane = WABITS_CHAN_Y; plane <= WABITS_CHAN_V; ++plane) {
        uint32_t planeHeight = frame.height;
        uint32_t planeWidthBytes = (plane == WABITS_CHAN_Y) ? frame.width : frame.width >> 1;
        uint8_t * row = image->planes[plane];
        for (uint32_t y = 0; y < planeHeight; ++y) {
            uint32_t bytesRead = (uint32_t)fread(row, 1, planeWidthBytes, frame.inputFile);
            if (bytesRead != planeWidthBytes) {
                fprintf(stderr,
                        "Failed to read y4m row (not enough data, wanted %u, got %u): %s\n",
                        planeWidthBytes,
                        bytesRead,
                        frame.displayFilename);
                goto cleanup;
            }
            row += planeWidthBytes;
        }
    }

    result = WABITS_TRUE;
cleanup:
    if (iter) {
        if (*iter) {
            free(*iter);
            *iter = NULL;
        }

        if (result && frame.inputFile) {
            ungetc(fgetc(frame.inputFile), frame.inputFile); // Kick frame.inputFile to force EOF

            if (!feof(frame.inputFile)) {
                // Remember y4m state for next time
                *iter = malloc(sizeof(struct y4mFrameIterator));
                if (*iter == NULL) {
                    fprintf(stderr, "Inter-frame state memory allocation failure\n");
                    result = WABITS_FALSE;
                } else {
                    **iter = frame;
                }
            }
        }
    }

    wabitsRWDataFree(&raw);
    return result;
}

// --------------------------------------------------------------------------------------
// Config + FFmpeg process management (Windows/WABITS_LUA only)

#ifdef WABITS_LUA

struct WabitsConfig
{
    char crop[256];
    char capture[256];
    int fps;
    int verbose;
};

static void wabitsConfigInit(struct WabitsConfig * cfg)
{
    memset(cfg, 0, sizeof(*cfg));
    strncpy(cfg->capture, "desktop", sizeof(cfg->capture) - 1);
    cfg->fps = 10;
    cfg->verbose = 0;
}

static int wabitsConfigParse(struct WabitsConfig * cfg, const char * filename)
{
    FILE * f = fopen(filename, "r");
    if (!f) {
        return 0;
    }

    char line[512];
    while (fgets(line, sizeof(line), f)) {
        char * p = line;
        while (*p == ' ' || *p == '\t')
            p++;
        if (*p == '#' || *p == '\n' || *p == '\r' || *p == '\0')
            continue;

        // Trim trailing whitespace
        char * end = p + strlen(p) - 1;
        while (end > p && (*end == '\n' || *end == '\r' || *end == ' ' || *end == '\t')) {
            *end = '\0';
            --end;
        }

        char * eq = strchr(p, '=');
        if (!eq)
            continue;
        *eq = '\0';
        char * key = p;
        char * val = eq + 1;

        if (!strcmp(key, "crop"))
            strncpy(cfg->crop, val, sizeof(cfg->crop) - 1);
        else if (!strcmp(key, "capture"))
            strncpy(cfg->capture, val, sizeof(cfg->capture) - 1);
        else if (!strcmp(key, "fps"))
            cfg->fps = atoi(val);
        else if (!strcmp(key, "verbose"))
            cfg->verbose = atoi(val);
    }
    fclose(f);
    return 1;
}

static HANDLE ffmpegProcess = NULL;
static HANDLE ffmpegJob = NULL;

static void ffmpegCleanup()
{
    if (ffmpegProcess) {
        TerminateProcess(ffmpegProcess, 0);
        WaitForSingleObject(ffmpegProcess, 2000);
        CloseHandle(ffmpegProcess);
        ffmpegProcess = NULL;
    }
    if (ffmpegJob) {
        CloseHandle(ffmpegJob);
        ffmpegJob = NULL;
    }
}

static FILE * ffmpegSpawn(const struct WabitsConfig * cfg)
{
    SECURITY_ATTRIBUTES sa = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };

    // Create pipe for ffmpeg stdout -> our input
    HANDLE pipeRead, pipeWrite;
    if (!CreatePipe(&pipeRead, &pipeWrite, &sa, 0)) {
        fprintf(stderr, "Failed to create pipe: %lu\n", GetLastError());
        return NULL;
    }
    SetHandleInformation(pipeRead, HANDLE_FLAG_INHERIT, 0);

    // Build ffmpeg command line
    char cmdline[2048];
    if (cfg->verbose) {
        snprintf(cmdline, sizeof(cmdline),
            "ffmpeg -y -f gdigrab -i %s -vf crop=%s -pix_fmt yuv422p -f yuv4mpegpipe -r %d -",
            cfg->capture, cfg->crop, cfg->fps);
    } else {
        snprintf(cmdline, sizeof(cmdline),
            "ffmpeg -hide_banner -loglevel error -y -f gdigrab -i %s -vf crop=%s -pix_fmt yuv422p -f yuv4mpegpipe -r %d -",
            cfg->capture, cfg->crop, cfg->fps);
    }
    printf("Starting: %s\n", cmdline);

    // Redirect stderr to NUL unless verbose
    HANDLE hStdErr;
    if (cfg->verbose) {
        hStdErr = GetStdHandle(STD_ERROR_HANDLE);
    } else {
        hStdErr = CreateFileA("NUL", GENERIC_WRITE, FILE_SHARE_WRITE, &sa, OPEN_EXISTING, 0, NULL);
    }

    STARTUPINFOA si;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = pipeWrite;
    si.hStdError = hStdErr;
    si.hStdInput = NULL;

    PROCESS_INFORMATION pi;
    ZeroMemory(&pi, sizeof(pi));

    // Create job object so ffmpeg dies if we crash
    ffmpegJob = CreateJobObject(NULL, NULL);
    if (ffmpegJob) {
        JOBOBJECT_EXTENDED_LIMIT_INFORMATION jeli;
        ZeroMemory(&jeli, sizeof(jeli));
        jeli.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
        SetInformationJobObject(ffmpegJob, JobObjectExtendedLimitInformation, &jeli, sizeof(jeli));
    }

    if (!CreateProcessA(NULL, cmdline, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
        fprintf(stderr, "Failed to start ffmpeg: %lu\n", GetLastError());
        fprintf(stderr, "Make sure ffmpeg is in your PATH.\n");
        CloseHandle(pipeRead);
        CloseHandle(pipeWrite);
        if (!cfg->verbose)
            CloseHandle(hStdErr);
        return NULL;
    }

    if (ffmpegJob) {
        AssignProcessToJobObject(ffmpegJob, pi.hProcess);
    }

    ffmpegProcess = pi.hProcess;
    CloseHandle(pi.hThread);
    CloseHandle(pipeWrite);
    if (!cfg->verbose)
        CloseHandle(hStdErr);

    // Convert pipe handle to FILE*
    int fd = _open_osfhandle((intptr_t)pipeRead, _O_RDONLY | _O_BINARY);
    if (fd == -1) {
        fprintf(stderr, "Failed to convert pipe handle\n");
        ffmpegCleanup();
        return NULL;
    }
    FILE * f = _fdopen(fd, "rb");
    if (!f) {
        fprintf(stderr, "Failed to create FILE from pipe\n");
        _close(fd);
        ffmpegCleanup();
        return NULL;
    }

    return f;
}

static int ffmpegCapturePng(const struct WabitsConfig * cfg, const char * filename)
{
    char cmdline[2048];
    snprintf(cmdline, sizeof(cmdline),
        "ffmpeg -y -f gdigrab -i %s -vf crop=%s -vframes 1 \"%s\"",
        cfg->capture, cfg->crop, filename);
    printf("Capturing: %s\n", cmdline);

    STARTUPINFOA si;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);

    PROCESS_INFORMATION pi;
    ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcessA(NULL, cmdline, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) {
        fprintf(stderr, "Failed to start ffmpeg: %lu\n", GetLastError());
        return 1;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);
    DWORD exitCode = 1;
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    if (exitCode == 0) {
        printf("Saved: %s\n", filename);
    }
    return (int)exitCode;
}

#endif // WABITS_LUA

// --------------------------------------------------------------------------------------

#define SERVERADDRESS "127.0.0.1"

int main(int argc, char * argv[])
{
#ifdef WABITS_LUA
    // Windows + Lua mode: read config, spawn ffmpeg internally
    struct WabitsConfig cfg;
    wabitsConfigInit(&cfg);
    if (!wabitsConfigParse(&cfg, "wabits.cfg")) {
        fprintf(stderr, "Could not open wabits.cfg\n");
        fprintf(stderr, "Copy wabits.cfg.example to wabits.cfg and edit the crop rectangle.\n");
        return 1;
    }
    if (cfg.crop[0] == '\0') {
        fprintf(stderr, "No crop= set in wabits.cfg\n");
        return 1;
    }

    // PNG capture mode: wabits.exe capture.png
    if (argc > 1) {
        return ffmpegCapturePng(&cfg, argv[1]);
    }

    FILE * inputFile = ffmpegSpawn(&cfg);
    if (!inputFile) {
        return 1;
    }

    if (!wlStartup()) {
        fclose(inputFile);
        ffmpegCleanup();
        return 1;
    }

#else
    // Mac (stdin pipe) or Windows without Lua (legacy UDP mode)
    FILE * inputFile = stdin;

#ifdef _WIN32
    _setmode(_fileno(stdin), _O_BINARY);

    WSADATA wsaData;
    int iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
    if (iResult != 0) {
        printf("WSAStartup failed: %d\n", iResult);
        return 1;
    }
#endif

    char udpBuffer[32];

    SOCKET sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        fprintf(stderr, "Error opening socket");
        return EXIT_FAILURE;
    }

    struct sockaddr_in server;
    memset(&server, 0, sizeof(struct sockaddr_in));
    server.sin_family = AF_INET;
    server.sin_addr.s_addr = inet_addr(SERVERADDRESS);
    server.sin_port = htons(9001);
#endif

    struct Image image;
    image.planes[0] = malloc(256 * 256);
    image.planes[1] = malloc(256 * 256);
    image.planes[2] = malloc(256 * 256);

    struct y4mFrameIterator * frameIter = NULL;

    for (;;) {
        if (feof(inputFile)) {
            break;
        }
        if (!y4mRead(inputFile, &image, &frameIter)) {
            break;
        }

        uint32_t bits = 0;
        uint8_t * yPlane = image.planes[0];
        for (int bitIndex = 0; bitIndex < 32; ++bitIndex) {
            int bitX = bitIndex % 4;
            int bitY = bitIndex / 4;
            int pixelX = (int)(2 + bitX * ((float)image.width / 4));
            int pixelY = (int)(2 + bitY * ((float)image.height / 8));
            uint8_t pixel = yPlane[pixelX + (pixelY * image.width)];
            if (pixel > 127) {
                bits += (1 << bitIndex);
            }
        }

#ifdef WABITS_LUA
        wlUpdate(bits);
#else
        sprintf(udpBuffer, "%u", bits);
        if (sendto(sockfd, udpBuffer, (int)strlen(udpBuffer), 0, (const struct sockaddr *)&server, sizeof(server)) < 0) {
            fprintf(stderr, "Error in sendto()\n");
            return -1;
        }
#endif
    }

#ifdef WABITS_LUA
    wlShutdown();
    fclose(inputFile);
    ffmpegCleanup();
#endif
    return 0;
}
