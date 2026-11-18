#!/bin/sh
# Runs Blender, again if it crashes. Blender 5.2 on Metal aborts now and then
# while it loads its Cycles kernels (an NSException in ShaderCache::load_kernel,
# "Abort trap: 6"), before it renders anything: a second run goes through.
# The Makefiles call it as $(BLENDER); BLENDER_BIN picks the real binary.
#   tools/blender.sh -b -P tools/render_studio.py -- ...
bin=${BLENDER_BIN:-blender}
tries=${BLENDER_TRIES:-4}
i=1
while :; do
    "$bin" "$@" && exit 0
    status=$?
    [ "$i" -ge "$tries" ] && exit "$status"
    echo "blender.sh: blender exited with $status, try $((i + 1)) of $tries" >&2
    i=$((i + 1))
done
