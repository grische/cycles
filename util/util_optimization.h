/*
 * Copyright 2011-2013 Blender Foundation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License
 */

#if defined(__x86_64__) || defined(_M_X64)

/* no SSE2 kernel on x86-64, part of regular kernel */
#define WITH_CYCLES_OPTIMIZED_KERNEL_SSE3
#define WITH_CYCLES_OPTIMIZED_KERNEL_SSE41

/* VC2008 is not ready for sse41, probably broken blendv intrinsic... */
#if defined(_MSC_VER) && (_MSC_VER < 1700)
#undef WITH_CYCLES_OPTIMIZED_KERNEL_SSE41
#endif

#endif

#if defined(i386) || defined(_M_IX86)

#define WITH_CYCLES_OPTIMIZED_KERNEL_SSE2
#define WITH_CYCLES_OPTIMIZED_KERNEL_SSE3

#endif
