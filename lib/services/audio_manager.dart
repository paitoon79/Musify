import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/ui/player.dart';

AudioPlayer audioPlayer = AudioPlayer();

final durationNotifier = ValueNotifier<Duration?>(Duration.zero);
final buttonNotifier = ValueNotifier<MPlayerState>(MPlayerState.stopped);
final shuffleNotifier = ValueNotifier<bool>(false);
final repeatNotifier = ValueNotifier<bool>(false);
final prefferedFileExtension = ValueNotifier<String>(
    Hive.box('settings').get('audioFileType', defaultValue: 'mp3') as String);
final playNextSongAutomatically = ValueNotifier<bool>(false);

bool get hasNext => activePlaylist.isEmpty
    ? audioPlayer.hasNext
    : id + 1 <= activePlaylist.length;

bool get hasPrevious =>
    activePlaylist.isEmpty ? audioPlayer.hasPrevious : id - 1 >= 0;

String get durationText =>
    duration != null ? duration.toString().split('.').first : '';

String get positionText =>
    position != null ? position.toString().split('.').first : '';

bool isMuted = false;

void play() => audioPlayer.play();

void pause() => audioPlayer.pause();

void stop() => audioPlayer.stop();

Future playNext() async {
  if (id + 1 <= activePlaylist.length) {
    id = id + 1;
    await playSong(activePlaylist[id]);
  }
}

Future playPrevious() async {
  if (id - 1 >= 0) {
    id = id - 1;
    await playSong(activePlaylist[id]);
  }
}

Future<void> playSong(Map song) async {
  await setSongDetails(song);
  play();
}

Future changeShuffleStatus() async {
  if (shuffleNotifier.value == true) {
    await audioPlayer.setShuffleModeEnabled(false);
  } else {
    await audioPlayer.setShuffleModeEnabled(true);
  }
}

void changeAutoPlayNextStatus() {
  if (playNextSongAutomatically.value == false) {
    playNextSongAutomatically.value = true;
  } else {
    playNextSongAutomatically.value = false;
  }
}

Future changeLoopStatus() async {
  if (repeatNotifier.value == false) {
    repeatNotifier.value = true;
    await audioPlayer.setLoopMode(LoopMode.one);
  } else {
    repeatNotifier.value = false;
    await audioPlayer.setLoopMode(LoopMode.off);
  }
}

Future mute(bool muted) async {
  if (muted) {
    await audioPlayer.setVolume(0);
  } else {
    await audioPlayer.setVolume(1);
  }
}
