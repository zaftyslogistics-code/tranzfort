import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/services/stt_service.dart';

void main() {
  test('STT service starts listening with Hindi locale, partial results, and timeout settings', () async {
    String? selectedLocaleId;
    bool? selectedPartialResults;
    Duration? selectedListenFor;
    Duration? selectedPauseFor;
    final partialResults = <String>[];
    final finalResults = <String>[];

    final service = SttService(
      initializeFn: ({required onError}) async => true,
      listenFn: ({
        required onResult,
        required localeId,
        required partialResults,
        required listenFor,
        required pauseFor,
      }) async {
        selectedLocaleId = localeId;
        selectedPartialResults = partialResults;
        selectedListenFor = listenFor;
        selectedPauseFor = pauseFor;
        onResult('थोड़ा text', false);
        onResult('अंतिम text', true);
      },
      stopFn: () async {},
      cancelFn: () async {},
      hasPermissionFn: () async => true,
      isListeningFn: () => false,
    );

    final outcome = await service.startListening(
      languageCode: 'hi',
      onPartialResult: partialResults.add,
      onFinalResult: finalResults.add,
    );

    expect(outcome, SttStartOutcome.started);
    expect(selectedLocaleId, 'hi_IN');
    expect(selectedPartialResults, isTrue);
    expect(selectedListenFor, SttService.defaultListenWindow);
    expect(selectedPauseFor, SttService.defaultSilenceTimeout);
    expect(partialResults, <String>['थोड़ा text']);
    expect(finalResults, <String>['अंतिम text']);
    expect(service.isListening, isFalse);
  });

  test('STT service returns permission denied when initialization fails without mic permission', () async {
    final service = SttService(
      initializeFn: ({required onError}) async {
        onError('permission_denied');
        return false;
      },
      listenFn: ({
        required onResult,
        required localeId,
        required partialResults,
        required listenFor,
        required pauseFor,
      }) async {},
      stopFn: () async {},
      cancelFn: () async {},
      hasPermissionFn: () async => false,
      isListeningFn: () => false,
    );

    final outcome = await service.startListening(
      languageCode: 'en',
      onPartialResult: (_) {},
      onFinalResult: (_) {},
    );

    expect(outcome, SttStartOutcome.permissionDenied);
    expect(service.lastErrorMessage, 'permission_denied');
  });

  test('STT service returns unavailable when initialization fails despite permission', () async {
    final service = SttService(
      initializeFn: ({required onError}) async {
        onError('service_unavailable');
        return false;
      },
      listenFn: ({
        required onResult,
        required localeId,
        required partialResults,
        required listenFor,
        required pauseFor,
      }) async {},
      stopFn: () async {},
      cancelFn: () async {},
      hasPermissionFn: () async => true,
      isListeningFn: () => false,
    );

    final outcome = await service.startListening(
      languageCode: 'en',
      onPartialResult: (_) {},
      onFinalResult: (_) {},
    );

    expect(outcome, SttStartOutcome.unavailable);
    expect(service.lastErrorMessage, 'service_unavailable');
  });

  test('STT service returns busy when a listening session is already active', () async {
    final service = SttService(
      initializeFn: ({required onError}) async => true,
      listenFn: ({
        required onResult,
        required localeId,
        required partialResults,
        required listenFor,
        required pauseFor,
      }) async {},
      stopFn: () async {},
      cancelFn: () async {},
      hasPermissionFn: () async => true,
      isListeningFn: () => true,
    );

    final outcome = await service.startListening(
      languageCode: 'en',
      onPartialResult: (_) {},
      onFinalResult: (_) {},
    );

    expect(outcome, SttStartOutcome.busy);
  });

  test('STT service stops and cancels listening safely', () async {
    var stopCalls = 0;
    var cancelCalls = 0;
    final service = SttService(
      initializeFn: ({required onError}) async => true,
      listenFn: ({
        required onResult,
        required localeId,
        required partialResults,
        required listenFor,
        required pauseFor,
      }) async {},
      stopFn: () async {
        stopCalls += 1;
      },
      cancelFn: () async {
        cancelCalls += 1;
      },
      hasPermissionFn: () async => true,
      isListeningFn: () => false,
    );

    await service.stopListening();
    await service.cancelListening();

    expect(stopCalls, 1);
    expect(cancelCalls, 1);
    expect(service.isListening, isFalse);
  });
}
