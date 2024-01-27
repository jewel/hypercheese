ENV['INLINEDIR'] = "/tmp/inline-#{Process.uid}"
Dir.mkdir(ENV['INLINEDIR']) unless File.exist? ENV['INLINEDIR']

class NativeFunctions
  inline do |builder|
    builder.add_compile_flags '-O3 -Wall -march=native -mfma'
    builder.include '<immintrin.h>'
    builder.include '<ruby/thread.h>'
    builder.include '<sys/mman.h>'

    builder.c_singleton '
double cosine_distance_old(VALUE a_str, VALUE b_str)
{
  int size = RSTRING_LEN(a_str) / 4;
  float* a = (float*) StringValuePtr( a_str );
  float* b = (float*) StringValuePtr( b_str );
  float dot_product = 0.0f, denom_a = 0.0f, denom_b = 0.0f;

  for( int i = 0; i < size; i++ ) {
    dot_product += a[i] * b[i];
    denom_a += a[i] * a[i];
    denom_b += b[i] * b[i];
  }

  double res = dot_product / (sqrt(denom_a) * sqrt(denom_b));
  return res;
}'

    # AVX2
    builder.c_singleton '
double cosine_distance_avx2(VALUE a_str, VALUE b_str)
{
  int size = RSTRING_LEN(a_str) / 4;
  float* a = (float*) StringValuePtr( a_str );
  float* b = (float*) StringValuePtr( b_str );
  __m256 dot_product = _mm256_setzero_ps();
  __m256 denom_a = _mm256_setzero_ps();
  __m256 denom_b = _mm256_setzero_ps();

  for( int i = 0; i < size; i += 8 ) {
    __m256 a_vec = _mm256_loadu_ps(&a[i]);
    __m256 b_vec = _mm256_loadu_ps(&b[i]);
    dot_product = _mm256_add_ps(dot_product, _mm256_mul_ps(a_vec, b_vec));
    denom_a = _mm256_add_ps(denom_a, _mm256_mul_ps(a_vec, a_vec));
    denom_b = _mm256_add_ps(denom_b, _mm256_mul_ps(b_vec, b_vec));
  }

  float dot_product_result = 0.0f;
  for( int i = 0; i < 8; i++ )
    dot_product_result += dot_product[i];

  float denom_a_result = 0.0f;
  for( int i = 0; i < 8; i++ )
    denom_a_result += denom_a[i];

  float denom_b_result = 0.0f;
  for( int i = 0; i < 8; i++ )
    denom_b_result += denom_b[i];

  double res = dot_product_result / (sqrt(denom_a_result) * sqrt(denom_b_result));
  return res;
}'

    # FMA
    builder.c_singleton '
double cosine_distance(VALUE a_str, VALUE b_str)
{
  int size = RSTRING_LEN(a_str) / 4;
  float* a = (float*) StringValuePtr( a_str );
  float* b = (float*) StringValuePtr( b_str );
  __m256 dot_product = _mm256_setzero_ps();
  __m256 denom_a = _mm256_setzero_ps();
  __m256 denom_b = _mm256_setzero_ps();

  for( int i = 0; i < size; i += 8 ) {
    __m256 a_vec = _mm256_loadu_ps(&a[i]);
    __m256 b_vec = _mm256_loadu_ps(&b[i]);
    dot_product = _mm256_fmadd_ps(a_vec, b_vec, dot_product);
    denom_a = _mm256_fmadd_ps(a_vec, a_vec, denom_a);
    denom_b = _mm256_fmadd_ps(b_vec, b_vec, denom_b);
  }

  float dot_product_result = 0.0f;
  for( int i = 0; i < 8; i++ )
    dot_product_result += dot_product[i];

  float denom_a_result = 0.0f;
  for( int i = 0; i < 8; i++ )
    denom_a_result += denom_a[i];

  float denom_b_result = 0.0f;
  for( int i = 0; i < 8; i++ )
    denom_b_result += denom_b[i];

  double res = dot_product_result / (sqrt(denom_a_result) * sqrt(denom_b_result));
  return res;
}'

    # Bulk FMA
    builder.c_singleton '
VALUE bulk_cosine_distance(VALUE a_str, VALUE all_str)
{
  int size = RSTRING_LEN(a_str) / 4;
  int count = RSTRING_LEN(all_str) / RSTRING_LEN(a_str);
  VALUE results = rb_ary_new();

  float* a = (float*) StringValuePtr( a_str );
  float* all = (float*) StringValuePtr( all_str );

  for( int j = 0; j < count; j++ ) {
    float* b = all + j * size;

    __m256 dot_product = _mm256_setzero_ps();
    __m256 denom_a = _mm256_setzero_ps();
    __m256 denom_b = _mm256_setzero_ps();

    for( int i = 0; i < size; i += 8 ) {
      __m256 a_vec = _mm256_loadu_ps(a + i);
      __m256 b_vec = _mm256_loadu_ps(b + i);
      dot_product = _mm256_fmadd_ps(a_vec, b_vec, dot_product);
      denom_a = _mm256_fmadd_ps(a_vec, a_vec, denom_a);
      denom_b = _mm256_fmadd_ps(b_vec, b_vec, denom_b);
    }

    float dot_product_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      dot_product_result += dot_product[i];

    float denom_a_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      denom_a_result += denom_a[i];

    float denom_b_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      denom_b_result += denom_b[i];

    float denom = (sqrt(denom_a_result) * sqrt(denom_b_result));
    if( denom == 0.0 )
      continue;

    VALUE indexed = rb_ary_new();
    float res = dot_product_result / denom;
    rb_ary_push(indexed, rb_float_new(res));
    rb_ary_push(indexed, rb_int_new(j));
    rb_ary_push(results, indexed);
  }
  return results;
}'

    builder.c_singleton '
VALUE bulk_cosine_distance_mmap(VALUE a_str, VALUE threshold, long total_size, int fd)
{
  size_t size = RSTRING_LEN(a_str) / 4;
  long count = total_size / RSTRING_LEN(a_str);
  VALUE results = rb_ary_new();

  float thresh = NUM2DBL(threshold);


  float* a = (float*) StringValuePtr( a_str );
  void* mapping = mmap(NULL, (size_t)total_size, PROT_READ, MAP_PRIVATE, fd, 0);
  if(mapping == MAP_FAILED)
    rb_raise(rb_eRuntimeError, "mmap failed");

  float* all = mapping;

  for( long j = 0; j < count; j++ ) {
    float* b = all + j * size;

    __m256 dot_product = _mm256_setzero_ps();
    __m256 denom_a = _mm256_setzero_ps();
    __m256 denom_b = _mm256_setzero_ps();

    for( int i = 0; i < size; i += 8 ) {
      __m256 a_vec = _mm256_loadu_ps(a + i);
      __m256 b_vec = _mm256_loadu_ps(b + i);
      dot_product = _mm256_fmadd_ps(a_vec, b_vec, dot_product);
      denom_a = _mm256_fmadd_ps(a_vec, a_vec, denom_a);
      denom_b = _mm256_fmadd_ps(b_vec, b_vec, denom_b);
    }

    float dot_product_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      dot_product_result += dot_product[i];

    float denom_a_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      denom_a_result += denom_a[i];

    float denom_b_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      denom_b_result += denom_b[i];

    float denom = (sqrt(denom_a_result) * sqrt(denom_b_result));
    if( denom == 0.0 )
      continue;

    float res = dot_product_result / denom;
    if( res < thresh )
      continue;
    VALUE indexed = rb_ary_new();
    rb_ary_push(indexed, rb_float_new(res));
    rb_ary_push(indexed, rb_int_new(j));
    rb_ary_push(results, indexed);
  }
  munmap(mapping, (size_t)total_size);
  return results;
}'
    builder.prefix '
typedef struct {
  int size;
  int count;
  float* a;
  float* all;
  float* res;
} bulk_distance_t;
'

    builder.prefix '
void* bulk_cosine_distance_no_gvl(void* arg)
{
  printf("here we go\n");
  bulk_distance_t* data = arg;
  for( int j = 0; j < data->count; j++ ) {
    float* b = data->all + j * data->size;

    __m256 dot_product = _mm256_setzero_ps();
    __m256 denom_a = _mm256_setzero_ps();
    __m256 denom_b = _mm256_setzero_ps();

    for( int i = 0; i < data->size; i += 8 ) {
      __m256 a_vec = _mm256_loadu_ps(data->a + i);
      __m256 b_vec = _mm256_loadu_ps(b + i);
      dot_product = _mm256_fmadd_ps(a_vec, b_vec, dot_product);
      denom_a = _mm256_fmadd_ps(a_vec, a_vec, denom_a);
      denom_b = _mm256_fmadd_ps(b_vec, b_vec, denom_b);
    }

    float dot_product_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      dot_product_result += dot_product[i];

    float denom_a_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      denom_a_result += denom_a[i];

    float denom_b_result = 0.0f;
    for( int i = 0; i < 8; i++ )
      denom_b_result += denom_b[i];

    float denom = (sqrt(denom_a_result) * sqrt(denom_b_result));

    data->res[j] = dot_product_result / denom;
    printf("%i %f\n", j, data->res[j]);
  }
  return NULL;
}
'

    builder.c_singleton '
VALUE bulk_cosine_distance_threadable(VALUE a_str, VALUE all_str, VALUE res)
{
  int count = RSTRING_LEN(all_str) / RSTRING_LEN(a_str);
  bulk_distance_t args = {
    .size = RSTRING_LEN(a_str) / 4,
    .count = count,
    .a = (float*) StringValuePtr( a_str ),
    .all = (float*) StringValuePtr( all_str ),
    .res = (float*) StringValuePtr( res ),
  };
  printf("about to launch\n");
  rb_thread_call_without_gvl(bulk_cosine_distance_no_gvl, &args, NULL, NULL);
  return Qnil;
}
'
  end
end

