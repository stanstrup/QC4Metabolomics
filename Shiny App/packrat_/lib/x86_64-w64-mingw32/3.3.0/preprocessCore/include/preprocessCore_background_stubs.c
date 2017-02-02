#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#ifndef PREPROCESSCORE_BACKGROUND_STUBS_H
#define PREPROCESSCORE_BACKGROUND_STUBS_H 1


void rma_bg_parameters(double *PM,double *param, size_t rows, size_t cols, size_t column){

  static void(*fun)(double *, double *, size_t, size_t, size_t) = NULL;

  if (fun == NULL)
    fun = (void(*)(double *, double *, size_t, size_t, size_t))R_GetCCallable("preprocessCore","rma_bg_parameters");

  fun(PM, param, rows, cols, column);
  return;
}


void rma_bg_adjust(double *PM,double *param, size_t rows, size_t cols, size_t column){

  static void(*fun)(double *, double *, size_t, size_t, size_t) = NULL;

  if (fun == NULL)
    fun = (void(*)(double *, double *, size_t, size_t, size_t))R_GetCCallable("preprocessCore","rma_bg_adjust");

  fun(PM, param, rows, cols, column);
  return;
}


void rma_bg_correct(double *PM, size_t rows, size_t cols){

  static void(*fun)(double *, size_t, size_t) = NULL;

  if (fun == NULL)
    fun = (void(*)(double *, size_t, size_t))R_GetCCallable("preprocessCore","rma_bg_correct");

  fun(PM, rows, cols);
  return;
}






#endif
