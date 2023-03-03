class NativeFunctions
  inline do |builder|
    builder.add_compile_flags '-O3 -Wall'
    builder.c_singleton '
double cosine_distance(VALUE a_str, VALUE b_str)
{
  int size = RSTRING_LEN(a_str) / 4;
  float* a = (float*) StringValuePtr( a_str );
  float* b = (float*) StringValuePtr( b_str );
  float dot_product = 0, denom_a = 0, denom_b = 0;

  for( int i = 0; i < size; i++ ) {
    dot_product += a[i] * b[i];
    denom_a += a[i] * a[i];
    denom_b += b[i] * b[i];
  }

  return dot_product / (sqrt(denom_a) * sqrt(denom_b));
}'
  end
end

