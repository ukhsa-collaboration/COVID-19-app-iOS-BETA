# Reporting

A package used for running / reporting automated tests. Currently, this runs integrity checks on the archived app, like so:

```bash
swift run Reporter --archive $ARCHIVE_PATH --output $REPORT_PATH
```

## Development

Note that Xcode runs the executable in a sandbox, so even though it can *run* the executable, it may not behave as expected.
