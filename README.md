# StudyOS Africa

StudyOS Africa is an Android-first, offline-first study app built with Flutter and SQLite for students using low-end devices.

It is designed to help students manage their courses, track real study time, follow a weekly timetable, and keep a lightweight local file library without depending on constant internet access or high-end hardware.

## Why It Exists

Many students need a study tool that is simple, reliable, and usable on budget Android phones. StudyOS Africa focuses on local-first study workflows so the core experience still works even with limited connectivity or weaker devices.

## MVP Features

- Courses CRUD
- Study timer
- Study session logging
- Recent Sessions
- Today Plan recommendation
- Weekly Timetable
- File Library for local PDF and image metadata
- SQLite persistence
- Tested on a real Android phone

## Tech Stack

- Flutter
- Dart
- SQLite (`sqflite`)
- `path`
- `file_picker`
- `open_filex`

## Running Locally

```bash
flutter pub get
flutter run
```
This project is currently focused on local Android development.

## Current Status

StudyOS Africa is currently in MVP stage.

The core study workflow is working:
- create courses
- start and stop study sessions
- save sessions locally
- review recent sessions
- get a simple recommendation for what to study next
- manage a weekly timetable
- keep a lightweight local file library

The app is currently local-first and offline-first, with no backend, sync, payments, or AI features.

## Roadmap / Next Steps

Planned next steps include:
- final MVP QA pass
- UI cleanup and consistency improvements
- better file library experience
- future expansion toward iOS support

## Notes

This repository currently represents the Android-first MVP direction of the project.