/*
 * Copyright 2011, Blender Foundation.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#ifndef __UTIL_TRANSFORM_H__
#define __UTIL_TRANSFORM_H__

#ifndef __KERNEL_GPU__
#include <string.h>
#endif

#include "util_math.h"
#include "util_types.h"

CCL_NAMESPACE_BEGIN

typedef struct Transform {
	float4 x, y, z, w; /* rows */
} Transform;

__device_inline float3 transform(const Transform *t, const float3 a)
{
	float4 b = {a.x, a.y, a.z, 1.0f};
	float3 c = {dot(t->x, b), dot(t->y, b), dot(t->z, b)};

	return c/dot(t->w, b);
}

__device_inline float3 transform_direction(const Transform *t, const float3 a)
{
	float4 b = {a.x, a.y, a.z, 0.0f};
	float3 c = {dot(t->x, b), dot(t->y, b), dot(t->z, b)};

	return c;
}

#ifndef __KERNEL_GPU__

__device_inline void print_transform(const char *label, const Transform& t)
{
	print_float4(label, t.x);
	print_float4(label, t.y);
	print_float4(label, t.z);
	print_float4(label, t.w);
	printf("\n");
}

__device_inline Transform transform_transpose(const Transform a)
{
	Transform t;

	t.x.x = a.x.x; t.x.y = a.y.x; t.x.z = a.z.x; t.x.w = a.w.x;
	t.y.x = a.x.y; t.y.y = a.y.y; t.y.z = a.z.y; t.y.w = a.w.y;
	t.z.x = a.x.z; t.z.y = a.y.z; t.z.z = a.z.z; t.z.w = a.w.z;
	t.w.x = a.x.w; t.w.y = a.y.w; t.w.z = a.z.w; t.w.w = a.w.w;

	return t;
}

__device_inline Transform operator*(const Transform a, const Transform b)
{
	Transform c = transform_transpose(b);
	Transform t;

	t.x = make_float4(dot(a.x, c.x), dot(a.x, c.y), dot(a.x, c.z), dot(a.x, c.w));
	t.y = make_float4(dot(a.y, c.x), dot(a.y, c.y), dot(a.y, c.z), dot(a.y, c.w));
	t.z = make_float4(dot(a.z, c.x), dot(a.z, c.y), dot(a.z, c.z), dot(a.z, c.w));
	t.w = make_float4(dot(a.w, c.x), dot(a.w, c.y), dot(a.w, c.z), dot(a.w, c.w));

	return t;
}

__device_inline Transform make_transform(float a, float b, float c, float d,
									float e, float f, float g, float h,
									float i, float j, float k, float l,
									float m, float n, float o, float p)
{
	Transform t;

	t.x.x = a; t.x.y = b; t.x.z = c; t.x.w = d;
	t.y.x = e; t.y.y = f; t.y.z = g; t.y.w = h;
	t.z.x = i; t.z.y = j; t.z.z = k; t.z.w = l;
	t.w.x = m; t.w.y = n; t.w.z = o; t.w.w = p;

	return t;
}

__device_inline Transform transform_translate(float3 t)
{
	return make_transform(
		1, 0, 0, t.x,
		0, 1, 0, t.y,
		0, 0, 1, t.z,
		0, 0, 0, 1);
}

__device_inline Transform transform_translate(float x, float y, float z)
{
	return transform_translate(make_float3(x, y, z));
}

__device_inline Transform transform_scale(float3 s)
{
	return make_transform(
		s.x, 0, 0, 0,
		0, s.y, 0, 0,
		0, 0, s.z, 0,
		0, 0, 0, 1);
}

__device_inline Transform transform_scale(float x, float y, float z)
{
	return transform_scale(make_float3(x, y, z));
}

__device_inline Transform transform_perspective(float fov, float n, float f)
{
	Transform persp = make_transform(
		1, 0, 0, 0,
		0, 1, 0, 0,
		0, 0, f / (f - n), -f*n / (f - n),
		0, 0, 1, 0);

	float inv_angle = 1.0f/tanf(0.5f*fov);

	Transform scale = transform_scale(inv_angle, inv_angle, 1);

	return scale * persp;
}

__device_inline Transform transform_rotate(float angle, float3 axis)
{
	float s = sinf(angle);
	float c = cosf(angle);
	float t = 1.f - c;

	axis = normalize(axis);

	return make_transform(
		axis.x*axis.x*t + c,
		axis.x*axis.y*t - s*axis.z,
		axis.x*axis.z*t + s*axis.y,
		0.0f,

		axis.y*axis.x*t + s*axis.z,
		axis.y*axis.y*t + c,
		axis.y*axis.z*t - s*axis.x,
		0.0f,

		axis.z*axis.x*t - s*axis.y,
		axis.z*axis.y*t + s*axis.x,
		axis.z*axis.z*t + c,
		0.0f,

		0.0f, 0.0f, 0.0f, 1.0f);
}

__device_inline Transform transform_euler(float3 euler)
{
	return
		transform_rotate(euler.x, make_float3(1.0f, 0.0f, 0.0f)) *
		transform_rotate(euler.y, make_float3(1.0f, 0.0f, 0.0f)) *
		transform_rotate(euler.z, make_float3(1.0f, 0.0f, 0.0f));
}

__device_inline Transform transform_orthographic(float znear, float zfar)
{
	return transform_scale(1.0f, 1.0f, 1.0f / (zfar-znear)) *
		transform_translate(0.0f, 0.0f, -znear);
}

__device_inline Transform transform_identity()
{
	return transform_scale(1.0f, 1.0f, 1.0f);
}

__device_inline bool operator==(const Transform& A, const Transform& B)
{
	return memcmp(&A, &B, sizeof(Transform)) == 0;
}

__device_inline bool operator!=(const Transform& A, const Transform& B)
{
	return !(A == B);
}

__device_inline float3 transform_get_column(const Transform *t, int column)
{
	return make_float3(t->x[column], t->y[column], t->z[column]);
}

Transform transform_inverse(const Transform& a);

#endif

CCL_NAMESPACE_END

#endif /* __UTIL_TRANSFORM_H__ */

