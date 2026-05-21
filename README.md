# Hexdera

Hexdera is a simple multiplayer hex-grid game built with Elm and the Lamdera framework.

The project is based on:

- [elm-hex-grid](https://github.com/whaypr/elm-hex-grid) - my fork updated for compatibility with Elm 0.19 (original project: [danneu/elm-hex-grid](https://github.com/danneu/elm-hex-grid))
  - It provides interactive hexagonal grid with features like shortest paths or fog of war
- [Lamdera example chat app](https://github.com/lamdera/example-apps/tree/master/chat)
  - It provides multiplayer architecture with real-time frontend/backend synchronization

You can try the game online here: [Hexdera Live Demo](https://hexdera-deploy.lamdera.app/)

## Development

Install dependencies:

```bash
npm install
```

Most tasks can be performed through the `lamdera` CLI (instead of e.g. `elm`). To see all available commands:

```bash
lamdera
```

For the most useful options, you can also use the helper scripts defined in `package.json`:

```bash
npm run <command>
```

Available commands:

- `reset` (or `lamdera reset`) to reset application's persistent state
- `dev` (or `lamdera live`) to run locally
- `build` (or `lamdera make src/Env.elm src/Types.elm src/Backend.elm src/Frontend.elm`) to build the app
  - Run `lamder make --optimize ...` to build with optimizations
- `deploy` (or `lamdera deploy`) to deploy the app
  - See the [docs](https://dashboard.lamdera.app/docs/deploying) for more information, or simply follow instructions of the `deploy` command
- `format:elm` (or `lamdera format --yes ./src/ ./external/hex-grid/ ./tests/`) to format the code
  - Run command `format:prettier` to format the README, or just `format` to format both
- `test` to run the tests
