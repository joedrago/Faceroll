#ifdef _WIN32
// Windows
#define _CRT_SECURE_NO_WARNINGS 1
#include <fcntl.h>
#include <io.h>
#ifdef WABITS_LUA
#include "wabits_lua.h"
#include <windows.h>
#include <shellapi.h>
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
    frame.depth = 8;
    frame.format = WABITS_PIXEL_FORMAT_YUV420;
    frame.inputFile = NULL;

    wabitsRWData raw = WABITS_DATA_EMPTY;
    wabitsRWDataRealloc(&raw, Y4M_MAX_LINE_SIZE);

    if (iter && *iter) {
        frame = **iter;
    } else {
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
        ADVANCE(10);

        char tmpBuffer[32];

        while (p != end) {
            switch (*p) {
                case 'W':
                    frame.width = y4mReadUnsignedInt((const char *)p + 1, (const char *)end);
                    break;
                case 'H':
                    frame.height = y4mReadUnsignedInt((const char *)p + 1, (const char *)end);
                    break;
                case 'C':
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
                case 'F':
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

            while ((*p != '\n') && (*p != ' ')) {
                ADVANCE(1);
            }
            if (*p == '\n') {
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
            ungetc(fgetc(frame.inputFile), frame.inputFile);

            if (!feof(frame.inputFile)) {
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
// Config + FFmpeg process management + System tray (Windows/WABITS_LUA only)

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

// --------------------------------------------------------------------------------------
// FFmpeg process management

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

    HANDLE pipeRead, pipeWrite;
    if (!CreatePipe(&pipeRead, &pipeWrite, &sa, 0)) {
        fprintf(stderr, "Failed to create pipe: %lu\n", GetLastError());
        return NULL;
    }
    SetHandleInformation(pipeRead, HANDLE_FLAG_INHERIT, 0);

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

    ffmpegJob = CreateJobObject(NULL, NULL);
    if (ffmpegJob) {
        JOBOBJECT_EXTENDED_LIMIT_INFORMATION jeli;
        ZeroMemory(&jeli, sizeof(jeli));
        jeli.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
        SetInformationJobObject(ffmpegJob, JobObjectExtendedLimitInformation, &jeli, sizeof(jeli));
    }

    if (!CreateProcessA(NULL, cmdline, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) {
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

// --------------------------------------------------------------------------------------
// System tray

#define WM_TRAYICON (WM_USER + 1)
#define WM_WORKER_DONE (WM_USER + 2)
#define ID_TRAY_EXIT 1001

static HWND g_trayWindow = NULL;
static NOTIFYICONDATAA g_nid;
static FILE * g_inputFile = NULL;
static volatile int g_workerRunning = 1;
static HANDLE g_workerHandle = NULL;

static HICON createKeyboardIcon()
{
    // 16x16 pixel art keyboard: D=body, k=key, space=transparent
    static const char * art[16] = {
        "                ",
        "                ",
        "DDDDDDDDDDDDDDDD",
        "DkkDkkDkkDkkDkkD",
        "DDDDDDDDDDDDDDDD",
        "DDkkDkkDkkDkkDDD",
        "DDDDDDDDDDDDDDDD",
        "DDDkkDkkDkkDDDDD",
        "DDDDDDDDDDDDDDDD",
        "DDDDkkkkkkkkDDDD",
        "DDDDDDDDDDDDDDDD",
        "                ",
        "                ",
        "                ",
        "                ",
        "                ",
    };

    const int S = 16;
    uint32_t pixels[16 * 16];
    for (int y = 0; y < S; y++) {
        for (int x = 0; x < S; x++) {
            switch (art[y][x]) {
                case 'D': pixels[y * S + x] = 0xFF505050; break;
                case 'k': pixels[y * S + x] = 0xFFE0E0E0; break;
                default:  pixels[y * S + x] = 0x00000000; break;
            }
        }
    }

    BITMAPV5HEADER bi;
    ZeroMemory(&bi, sizeof(bi));
    bi.bV5Size = sizeof(bi);
    bi.bV5Width = S;
    bi.bV5Height = -S; // top-down
    bi.bV5Planes = 1;
    bi.bV5BitCount = 32;
    bi.bV5Compression = BI_BITFIELDS;
    bi.bV5RedMask = 0x00FF0000;
    bi.bV5GreenMask = 0x0000FF00;
    bi.bV5BlueMask = 0x000000FF;
    bi.bV5AlphaMask = 0xFF000000;

    void * bits;
    HDC dc = GetDC(NULL);
    HBITMAP colorBmp = CreateDIBSection(dc, (BITMAPINFO *)&bi, DIB_RGB_COLORS, &bits, NULL, 0);
    memcpy(bits, pixels, sizeof(pixels));
    ReleaseDC(NULL, dc);

    HBITMAP maskBmp = CreateBitmap(S, S, 1, 1, NULL);

    ICONINFO ii;
    ii.fIcon = TRUE;
    ii.xHotspot = 0;
    ii.yHotspot = 0;
    ii.hbmMask = maskBmp;
    ii.hbmColor = colorBmp;

    HICON icon = CreateIconIndirect(&ii);

    DeleteObject(colorBmp);
    DeleteObject(maskBmp);

    return icon;
}

static LRESULT CALLBACK trayWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
        case WM_TRAYICON:
            if (lParam == WM_RBUTTONUP) {
                HMENU menu = CreatePopupMenu();
                AppendMenuA(menu, MF_STRING | MF_GRAYED, 0, "Faceroll");
                AppendMenuA(menu, MF_SEPARATOR, 0, NULL);
                AppendMenuA(menu, MF_STRING, ID_TRAY_EXIT, "Exit");
                POINT pt;
                GetCursorPos(&pt);
                SetForegroundWindow(hwnd);
                TrackPopupMenu(menu, TPM_RIGHTALIGN | TPM_BOTTOMALIGN, pt.x, pt.y, 0, hwnd, NULL);
                DestroyMenu(menu);
            }
            break;
        case WM_COMMAND:
            if (LOWORD(wParam) == ID_TRAY_EXIT) {
                DestroyWindow(hwnd);
            }
            break;
        case WM_WORKER_DONE:
            DestroyWindow(hwnd);
            break;
        case WM_DESTROY:
            Shell_NotifyIconA(NIM_DELETE, &g_nid);
            PostQuitMessage(0);
            break;
        default:
            return DefWindowProcA(hwnd, msg, wParam, lParam);
    }
    return 0;
}

static void trayCreate()
{
    WNDCLASSEXA wc;
    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = trayWndProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = "WabitsTray";
    RegisterClassExA(&wc);

    g_trayWindow = CreateWindowExA(0, "WabitsTray", "Wabits", 0,
        0, 0, 0, 0, HWND_MESSAGE, NULL, wc.hInstance, NULL);

    ZeroMemory(&g_nid, sizeof(g_nid));
    g_nid.cbSize = sizeof(g_nid);
    g_nid.hWnd = g_trayWindow;
    g_nid.uID = 1;
    g_nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    g_nid.uCallbackMessage = WM_TRAYICON;
    g_nid.hIcon = createKeyboardIcon();
    strncpy(g_nid.szTip, "Faceroll", sizeof(g_nid.szTip) - 1);
    Shell_NotifyIconA(NIM_ADD, &g_nid);
}

static DWORD WINAPI y4mWorkerThread(LPVOID param)
{
    struct Image image;
    image.planes[0] = malloc(256 * 256);
    image.planes[1] = malloc(256 * 256);
    image.planes[2] = malloc(256 * 256);

    struct y4mFrameIterator * frameIter = NULL;

    while (g_workerRunning) {
        if (feof(g_inputFile))
            break;
        if (!y4mRead(g_inputFile, &image, &frameIter))
            break;

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
        wlUpdate(bits);
    }

    free(image.planes[0]);
    free(image.planes[1]);
    free(image.planes[2]);

    // Tell the main thread we're done
    if (g_trayWindow) {
        PostMessage(g_trayWindow, WM_WORKER_DONE, 0, 0);
    }
    return 0;
}

#endif // WABITS_LUA

// --------------------------------------------------------------------------------------

#define SERVERADDRESS "127.0.0.1"

int main(int argc, char * argv[])
{
#ifdef WABITS_LUA
    // Redirect all output to log file (truncated on startup)
    freopen("wabits.log", "w", stdout);
    _dup2(_fileno(stdout), _fileno(stderr));
    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

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

    // PNG capture mode: wabits.exe capture.png (allowed alongside a running instance)
    if (argc > 1) {
        return ffmpegCapturePng(&cfg, argv[1]);
    }

    // Single instance check (only for the tray/capture mode, not PNG)
    HANDLE instanceMutex = CreateMutexA(NULL, TRUE, "WabitsFacerollMutex");
    if (GetLastError() == ERROR_ALREADY_EXISTS) {
        CloseHandle(instanceMutex);
        return 0;
    }

    g_inputFile = ffmpegSpawn(&cfg);
    if (!g_inputFile) {
        return 1;
    }

    if (!wlStartup()) {
        fclose(g_inputFile);
        ffmpegCleanup();
        return 1;
    }

    // Create tray icon and start worker thread
    trayCreate();
    g_workerHandle = CreateThread(NULL, 0, y4mWorkerThread, NULL, 0, NULL);

    // Main thread runs the message pump
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    // Cleanup
    g_workerRunning = 0;
    wlShutdown();
    ffmpegCleanup();
    if (g_workerHandle) {
        WaitForSingleObject(g_workerHandle, 3000);
        CloseHandle(g_workerHandle);
    }
    fclose(g_inputFile);

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

        sprintf(udpBuffer, "%u", bits);
        if (sendto(sockfd, udpBuffer, (int)strlen(udpBuffer), 0, (const struct sockaddr *)&server, sizeof(server)) < 0) {
            fprintf(stderr, "Error in sendto()\n");
            return -1;
        }
    }
#endif
    return 0;
}
