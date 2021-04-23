# `gotrue-dart`

Dart client for the [GoTrue](https://github.com/netlify/gotrue) API.

[![pub package](https://img.shields.io/pub/v/gotrue.svg)](https://pub.dev/packages/gotrue)
[![pub test](https://github.com/supabase/gotrue-dart/workflows/Test/badge.svg)](https://github.com/supabase/gotrue-dart/actions?query=workflow%3ATest)

## Using

The usage should be the same as gotrue-js except:

Oauth2:

- `signIn` with oauth2 provider only return provider url. Users have to launch that url to continue the auth flow. I recommend to use [url_launcher](https://pub.dev/packages/url_launcher) package.
- After receiving callback uri from oauth2 provider, use `getSessionFromUrl` to parse session data.

Persist/restore session:

- Users can restore previous session by calling `await supabaseClient.auth.recoverSession()`
- Exposed `recoverSession` method allows manual session recovery from the given json string.

## Contributing

- Fork the repo on [GitHub](https://github.com/supabase/gotrue-dart)
- Clone the project to your own machine
- Commit changes to your own branch
- Push your work back up to your fork
- Submit a Pull request so that we can review your changes and merge

## License

This repo is licensed under MIT.

## Credits

- https://github.com/supabase/gotrue-js - ported from supabase/gotrue-js fork
- https://github.com/netlify/gotrue-js - original library
