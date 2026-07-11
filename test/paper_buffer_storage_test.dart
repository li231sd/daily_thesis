import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_thesis/models/paper.dart';
import 'package:daily_thesis/services/paper_buffer_storage.dart';

Paper _paper(String url, {String title = 'Untitled'}) => Paper(
      title: title,
      abstract: 'abstract',
      authors: 'authors',
      journal: 'journal',
      url: url,
      source: 'arxiv',
    );

void main() {
  setUp(() {
    // Fresh mock prefs backing store before every test.
    SharedPreferences.setMockInitialValues({});
  });

  group('PaperBufferStorage', () {
    test('starts empty', () async {
      final storage = PaperBufferStorage();
      expect(await storage.load(), isEmpty);
      expect(await storage.count(), 0);
      expect(await storage.popNext(), isNull);
    });

    test('addIfRoom adds new candidates up to targetSize', () async {
      final storage = PaperBufferStorage();
      final candidates = List.generate(
        PaperBufferStorage.targetSize + 5,
        (i) => _paper('https://example.com/$i'),
      );

      await storage.addIfRoom(candidates);

      expect(await storage.count(), PaperBufferStorage.targetSize);
    });

    test('addIfRoom skips urls already in excludeUrls', () async {
      final storage = PaperBufferStorage();
      final candidates = [
        _paper('https://example.com/seen'),
        _paper('https://example.com/new'),
      ];

      await storage.addIfRoom(
        candidates,
        excludeUrls: {'https://example.com/seen'},
      );

      final loaded = await storage.load();
      expect(loaded.map((p) => p.url), ['https://example.com/new']);
    });

    test('addIfRoom skips urls already queued (no duplicates)', () async {
      final storage = PaperBufferStorage();
      await storage.addIfRoom([_paper('https://example.com/a')]);
      await storage.addIfRoom([_paper('https://example.com/a'), _paper('https://example.com/b')]);

      final loaded = await storage.load();
      expect(loaded.map((p) => p.url), ['https://example.com/a', 'https://example.com/b']);
    });

    test('addIfRoom skips papers with empty url', () async {
      final storage = PaperBufferStorage();
      await storage.addIfRoom([_paper('')]);
      expect(await storage.count(), 0);
    });

    test('addIfRoom is a no-op once buffer is already full', () async {
      final storage = PaperBufferStorage();
      final fill = List.generate(
        PaperBufferStorage.targetSize,
        (i) => _paper('https://example.com/fill-$i'),
      );
      await storage.addIfRoom(fill);

      await storage.addIfRoom([_paper('https://example.com/extra')]);

      final loaded = await storage.load();
      expect(loaded.length, PaperBufferStorage.targetSize);
      expect(loaded.any((p) => p.url == 'https://example.com/extra'), isFalse);
    });

    test('popNext returns papers in FIFO order and removes them', () async {
      final storage = PaperBufferStorage();
      await storage.addIfRoom([
        _paper('https://example.com/1'),
        _paper('https://example.com/2'),
      ]);

      final first = await storage.popNext();
      expect(first?.url, 'https://example.com/1');
      expect(await storage.count(), 1);

      final second = await storage.popNext();
      expect(second?.url, 'https://example.com/2');
      expect(await storage.count(), 0);

      expect(await storage.popNext(), isNull);
    });

    test('clear empties the buffer', () async {
      final storage = PaperBufferStorage();
      await storage.addIfRoom([_paper('https://example.com/1')]);
      await storage.clear();
      expect(await storage.count(), 0);
    });
  });
}
