// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "misc.h"

#include <assert.h>
#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

// <dirent.h>

char *misc_d_name_ptr(struct misc_dirent *d) { return d->d_name; }

int misc_closedir(misc_DIR *d, int *err) {
  errno = *err;
  int r = closedir(d->_dir);
  *err = errno;
  free(d);
  return r;
}

misc_DIR *misc_fdopendir(int fd, int *err) {
  errno = *err;
  DIR *d = fdopendir(fd);
  *err = errno;
  if (d == NULL) {
    return NULL;
  }
  misc_DIR *myd = malloc(sizeof(misc_DIR));
  myd->_dir = d;
  return myd;
}

misc_DIR *misc_opendir(const char *path, int *err) {
  errno = *err;
  DIR *d = opendir(path);
  *err = errno;
  if (d == NULL) {
    return NULL;
  }
  misc_DIR *myd = malloc(sizeof(misc_DIR));
  myd->_dir = d;
  return myd;
}

struct misc_dirent *misc_readdir(misc_DIR *myd, int *err) {
  errno = *err;
  struct dirent *d = readdir(myd->_dir);
  *err = errno;
  if (d == NULL) {
    return NULL;
  }

  myd->misc_dirent.d_ino = d->d_ino;
  myd->misc_dirent.d_type = d->d_type;
  assert(strlen(myd->misc_dirent.d_name) <
         sizeof(myd->misc_dirent.d_name));
  strncpy(myd->misc_dirent.d_name, d->d_name,
          sizeof(myd->misc_dirent.d_name));
  return &(myd->misc_dirent);
}

// <sys/stat.h>

static void _fill(struct misc_Stat *buf, struct stat *s) {
  buf->st_dev = s->st_dev;
  buf->st_ino = s->st_ino;
  buf->st_mode = s->st_mode;
  buf->st_nlink = s->st_nlink;
  buf->std_uid = s->st_uid;
  buf->st_size = s->st_size;
#ifdef __APPLE__
  buf->st_atim.tv_sec = s->st_atimespec.tv_sec;
  buf->st_atim.tv_nsec = s->st_atimespec.tv_nsec;

  buf->st_ctim.tv_sec = s->st_ctimespec.tv_sec;
  buf->st_ctim.tv_nsec = s->st_ctimespec.tv_nsec;

  buf->st_mtim.tv_sec = s->st_mtimespec.tv_sec;
  buf->st_mtim.tv_nsec = s->st_mtimespec.tv_nsec;

  buf->st_btime.tv_sec = s->st_birthtimespec.tv_sec;
  buf->st_btime.tv_nsec = s->st_birthtimespec.tv_nsec;

  buf->st_flags = s->st_flags;
#elif __linux__
  // https://man7.org/linux/man-pages/man3/stat.3type.html

  buf->st_atim.tv_sec = s->st_atim.tv_sec;
  buf->st_atim.tv_nsec = s->st_atim.tv_nsec;

  buf->st_ctim.tv_sec = s->st_ctim.tv_sec;
  buf->st_ctim.tv_nsec = s->st_ctim.tv_nsec;

  buf->st_mtim.tv_sec = s->st_mtim.tv_sec;
  buf->st_mtim.tv_nsec = s->st_mtim.tv_nsec;
#endif
}

int misc_stat(const char *path, struct misc_Stat *buf, int *err) {
  struct stat s;
  errno = *err;
  int r = stat(path, &s);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int misc_lstat(const char *path, struct misc_Stat *buf, int *err) {
  struct stat s;
  errno = *err;
  int r = lstat(path, &s);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int misc_fstat(int fd, struct misc_Stat *buf, int *err) {
  struct stat s;
  errno = *err;
  int r = fstat(fd, &s);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}

int misc_fstatat(int fd, char *path, struct misc_Stat *buf,
                      int flag, int *err) {
  struct stat s;
  errno = *err;
  int r = fstatat(fd, path, &s, flag);
  *err = errno;
  if (r != -1) {
    _fill(buf, &s);
  }
  return r;
}
