# Copyright (C) 2018 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

def _generate_impl(ctx):
    ctx.file_action(
        output = ctx.outputs.output,
        content = ctx.attr.content,
    )

generate = rule(
    _generate_impl,
    attrs = {
        "output" : attr.output(mandatory=True),
        "content" : attr.string(mandatory=True),
    },
)

def _copy(ctx, src, dst):
    ctx.actions.run_shell(
        command = "cp \"" + src.path + "\" \"" + dst.path + "\"",
        inputs = [src],
        outputs = [dst]
    )

def _copy_impl(ctx):
    _copy(ctx, ctx.file.src, ctx.outputs.dst)

copy = rule(
    _copy_impl,
    attrs = {
        "src": attr.label(
            single_file = True,
            allow_files = True,
            mandatory = True,
        ),
        "dst": attr.output(),
    },
    executable = False,
)

def _copy_to_impl(ctx):
    filtered = []
    if not ctx.attr.extensions:
        filtered = ctx.files.srcs
    else:
        for src in ctx.files.srcs:
            if src.extension in ctx.attr.extensions:
                filtered += [src]
    outs = depset()
    for src in filtered:
        dstname = ctx.attr.rename.get(key = src.basename, default = src.basename)
        dst = ctx.new_file(ctx.bin_dir, ctx.attr.to + "/" + dstname)
        outs += [dst]
        _copy(ctx, src, dst)

    return struct(
        files = outs,
    )

copy_to = rule(
    _copy_to_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "extensions": attr.string_list(),
        "rename": attr.string_dict(),
        "to": attr.string(
            mandatory=True,
        ),
    },
)


def _copy_tree_impl(ctx):
    outs = depset()
    for src in ctx.files.srcs:
        path = src.path
        if path.startswith(ctx.attr.strip):
            path = path[len(ctx.attr.strip):]
        if ctx.attr.to:
            path = ctx.attr.to + "/" + path
        dst = ctx.new_file(ctx.bin_dir, path)
        outs += [dst]
        _copy(ctx, src, dst)

    return struct(
        files = outs,
    )

copy_tree = rule(
    _copy_tree_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
        ),
        "strip": attr.string(),
        "to": attr.string(),
    },
)

def filter_impl(ctx):
    return [
        DefaultInfo(
            files=depset([
                src for src in ctx.files.srcs
                if any([
                    src.basename.endswith(ext) for ext in ctx.attr.suffix
                ])
            ]),
        ),
    ]

filter = rule(
    filter_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "suffix": attr.string_list(),
    },
)
