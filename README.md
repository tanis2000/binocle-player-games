# Binocle Player Games

This repository contains example games for [Binocle Player](https://github.com/tanis2000/binocle-player)

## Running the games

They can be run with the following command

```sh
/path/to/binocle-player-executable/binocle-player ./<directory of the game>

# e.g.
/Users/tanis/Documents/binocle-player/build/binocle-player ./simple
```

## Debugging the games

The games can be debugged using a fork of @tomblind's local-lua-debugger-vscode.

Unfortunately the original project can't be used as it is missing some needed PRs that have not yet been merged into master and published in VSCode marketplace.

Just clone the following repository: [https://github.com/tanis2000/local-lua-debugger-vscode/tree/binocle](https://github.com/tanis2000/local-lua-debugger-vscode/tree/binocle)

Make sure that you checkout the `binocle` branch and then run:

```sh
npm run build
```

This will produce a .vsix package that can be installed from VSCode.
