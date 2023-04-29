## Automation scripts

Note: Scripts rely on some commands and will not properly run without them.

### Requirements for each scripts

- docker-shell, docker-start, docker-stop

    - requires `docker`


- download_github_file

        - requires `curl`


- download_github_subfolder

        - requires `curl`, `awk` and `jq`


- godot4-source-build, godot3-source-build

        - requires `pyston-scon` (u can change to `scons` but `pyston-scon` linking is faster.)


- set_brightness

        - assuming user run `i3wm` desktop environment in laptop


- ultimate_typing_build (for linux and windows)

        - `godot` (Godot 4.x)
        - project folder at `~/godot4Projects/typing_practice`


- webp2gif_all.sh (webp video to gif file converter)

        - python with `PIL` dependency
