# Changelog

## 0.1.6

- Add safe `Decimal` decoding from JSON numbers and numeric strings.
- Add `@SafeEnum` and `@SafeEnumOptional` for raw-value enums backed by `String`, `Int`, `Double`, `Float`, or `Bool`.
- Improve default-value lookup for property wrappers.

## 0.1.5

- Rebuild the package using Xcode's standard Swift package layout.
- Restore package metadata, tests, documentation, license, and release hygiene.
- Keep all SafeCodable runtime features from `0.1.4`, including URL decoding.

## 0.1.4

- Add safe `URL` decoding from JSON strings.
- Invalid or empty URL strings fall back to default values for non-optional `URL` properties.

## 0.1.3

- Fix external module conformance for app models that declare `struct Model: SafeCodable`.
- Make the `AnySafeCodable.safeDecodeAny(from:defaultValue:)` default implementation publicly available through `SafeCodable`.

## 0.1.2

- Expand Chinese and English usage documentation with JSON examples, model definitions, decode calls, and expected conversion results.
- Add explicit documentation for primitive type coercion cases such as number to string, string to number, string to boolean, and invalid values falling back to defaults.

## 0.1.1

- Add `@SafeDictionary` for decoding object fields into `[String: Any]`.
- Support encoding `@SafeDictionary` values back to JSON.
- Document number and boolean to string coercion.

## 0.1.0

- Add one-line safe decoding for `SafeCodable` models.
- Add root array decoding for `[Model].safeDecode(from:)`.
- Add JSON encoding helpers for data, string, dictionary, and array output.
- Add fallback behavior for missing, `null`, and invalid fields.
- Add primitive coercion for common `String`, `Int`, `Double`, `Float`, and `Bool` mismatches.
- Add nested model decoding and lossy array handling.
- Add `Date` support for ISO-8601, common date formats, and second/millisecond timestamps.
- Add `Data` Base64 decoding and encoding support.
- Add Chinese and English documentation.
