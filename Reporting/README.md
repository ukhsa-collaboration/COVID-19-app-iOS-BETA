# Reporting

A package used for running / reporting automated tests.

You can run integrity checks in different wasy

### From an archive

```bash
swift run Reporter archive $ARCHIVE_PATH --output $REPORT_PATH
```

### From an ipa

```bash
swift run Reporter ipa $IPA_PATH --output $REPORT_PATH
```

### From an Xcode project

```bash
swift run Reporter project $PROJECT_PATH --scheme $SCHEME --method archive --output AppReport
```

or

```bash
swift run Reporter project $PROJECT_PATH --scheme $SCHEME --method build --output AppReport
```

Using the archive method produces a more accurate result, but requires correct profiles / certificates to already be in place.

## Development

Note that Xcode runs the executable in a sandbox, so even though it can *run* the executable, it may not behave as expected.
