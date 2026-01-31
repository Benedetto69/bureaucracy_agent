/// Utility per calcolare scadenze e validare termini di ricorso
class DeadlineCalculator {
  /// Termine massimo per ricorso al Prefetto (giorni)
  static const int prefettoDeadlineDays = 60;

  /// Termine massimo per ricorso al Giudice di Pace (giorni)
  static const int giudicePaceDeadlineDays = 30;

  /// Termine per pagamento ridotto (giorni)
  static const int earlyPaymentDays = 5;

  /// Soglia di avviso "termine vicino" (giorni rimanenti)
  static const int warningThresholdDays = 15;

  /// Soglia di avviso "urgente" (giorni rimanenti)
  static const int urgentThresholdDays = 5;

  /// Calcola i giorni trascorsi dalla notifica
  static int daysSinceNotification(DateTime notificationDate) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfNotification = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
    );
    return startOfToday.difference(startOfNotification).inDays;
  }

  /// Calcola i giorni rimanenti per il ricorso al Prefetto
  static int daysRemainingForPrefetto(DateTime notificationDate) {
    final elapsed = daysSinceNotification(notificationDate);
    return prefettoDeadlineDays - elapsed;
  }

  /// Calcola i giorni rimanenti per il ricorso al Giudice di Pace
  static int daysRemainingForGiudicePace(DateTime notificationDate) {
    final elapsed = daysSinceNotification(notificationDate);
    return giudicePaceDeadlineDays - elapsed;
  }

  /// Calcola i giorni rimanenti per il pagamento ridotto
  static int daysRemainingForEarlyPayment(DateTime notificationDate) {
    final elapsed = daysSinceNotification(notificationDate);
    return earlyPaymentDays - elapsed;
  }

  /// Calcola la data di scadenza per il ricorso al Prefetto
  static DateTime prefettoDeadlineDate(DateTime notificationDate) {
    return notificationDate.add(const Duration(days: prefettoDeadlineDays));
  }

  /// Calcola la data di scadenza per il ricorso al Giudice di Pace
  static DateTime giudicePaceDeadlineDate(DateTime notificationDate) {
    return notificationDate.add(const Duration(days: giudicePaceDeadlineDays));
  }

  /// Verifica lo stato della scadenza
  static DeadlineStatus getDeadlineStatus(DateTime notificationDate) {
    final daysRemaining = daysRemainingForPrefetto(notificationDate);

    if (daysRemaining < 0) {
      return DeadlineStatus.expired;
    } else if (daysRemaining <= urgentThresholdDays) {
      return DeadlineStatus.urgent;
    } else if (daysRemaining <= warningThresholdDays) {
      return DeadlineStatus.warning;
    } else {
      return DeadlineStatus.ok;
    }
  }

  /// Genera un messaggio descrittivo sullo stato della scadenza
  static DeadlineInfo getDeadlineInfo(DateTime notificationDate) {
    final daysSince = daysSinceNotification(notificationDate);
    final daysRemainingPrefetto = daysRemainingForPrefetto(notificationDate);
    final daysRemainingGdP = daysRemainingForGiudicePace(notificationDate);
    final daysRemainingPayment = daysRemainingForEarlyPayment(notificationDate);
    final status = getDeadlineStatus(notificationDate);

    String title;
    String message;
    List<DeadlineAction> actions = [];

    switch (status) {
      case DeadlineStatus.expired:
        title = 'Termini scaduti';
        message = 'Sono passati $daysSince giorni dalla notifica. '
            'I termini ordinari per il ricorso sono scaduti.';
        actions = [
          const DeadlineAction(
            label: 'Verifica ricorso tardivo',
            description: 'In alcuni casi è ancora possibile ricorrere',
            type: DeadlineActionType.info,
          ),
        ];
        break;

      case DeadlineStatus.urgent:
        title = 'Scadenza imminente!';
        message = 'Hai solo $daysRemainingPrefetto giorni per il ricorso al Prefetto. '
            'Agisci subito!';
        actions = [
          DeadlineAction(
            label: 'Ricorso Prefetto',
            description: '$daysRemainingPrefetto giorni rimasti',
            type: DeadlineActionType.urgent,
          ),
          if (daysRemainingGdP > 0)
            DeadlineAction(
              label: 'Giudice di Pace',
              description: 'Scaduto ($daysRemainingGdP giorni fa)',
              type: DeadlineActionType.expired,
            ),
        ];
        break;

      case DeadlineStatus.warning:
        title = 'Termine in avvicinamento';
        message = 'Restano $daysRemainingPrefetto giorni per il ricorso al Prefetto. '
            'Pianifica con attenzione.';
        actions = [
          DeadlineAction(
            label: 'Ricorso Prefetto',
            description: '$daysRemainingPrefetto giorni rimasti',
            type: DeadlineActionType.warning,
          ),
          if (daysRemainingGdP > 0)
            DeadlineAction(
              label: 'Giudice di Pace',
              description: '$daysRemainingGdP giorni rimasti',
              type: daysRemainingGdP <= urgentThresholdDays
                  ? DeadlineActionType.urgent
                  : DeadlineActionType.warning,
            ),
        ];
        break;

      case DeadlineStatus.ok:
        title = 'Termini regolari';
        message = 'Hai ancora $daysRemainingPrefetto giorni per il ricorso al Prefetto.';
        actions = [
          DeadlineAction(
            label: 'Ricorso Prefetto',
            description: '$daysRemainingPrefetto giorni rimasti',
            type: DeadlineActionType.ok,
          ),
          if (daysRemainingGdP > 0)
            DeadlineAction(
              label: 'Giudice di Pace',
              description: '$daysRemainingGdP giorni rimasti',
              type: daysRemainingGdP <= warningThresholdDays
                  ? DeadlineActionType.warning
                  : DeadlineActionType.ok,
            ),
          if (daysRemainingPayment > 0)
            DeadlineAction(
              label: 'Pagamento ridotto',
              description: '$daysRemainingPayment giorni rimasti (-30%)',
              type: daysRemainingPayment <= 2
                  ? DeadlineActionType.urgent
                  : DeadlineActionType.ok,
            ),
        ];
        break;
    }

    return DeadlineInfo(
      status: status,
      title: title,
      message: message,
      daysSinceNotification: daysSince,
      daysRemainingPrefetto: daysRemainingPrefetto,
      daysRemainingGiudicePace: daysRemainingGdP,
      daysRemainingEarlyPayment: daysRemainingPayment,
      prefettoDeadline: prefettoDeadlineDate(notificationDate),
      giudicePaceDeadline: giudicePaceDeadlineDate(notificationDate),
      actions: actions,
    );
  }
}

/// Stato della scadenza
enum DeadlineStatus {
  /// Termini scaduti
  expired,

  /// Meno di 5 giorni rimasti
  urgent,

  /// Meno di 15 giorni rimasti
  warning,

  /// Più di 15 giorni rimasti
  ok,
}

/// Tipo di azione suggerita
enum DeadlineActionType {
  ok,
  warning,
  urgent,
  expired,
  info,
}

/// Azione suggerita per la scadenza
class DeadlineAction {
  final String label;
  final String description;
  final DeadlineActionType type;

  const DeadlineAction({
    required this.label,
    required this.description,
    required this.type,
  });
}

/// Informazioni complete sulla scadenza
class DeadlineInfo {
  final DeadlineStatus status;
  final String title;
  final String message;
  final int daysSinceNotification;
  final int daysRemainingPrefetto;
  final int daysRemainingGiudicePace;
  final int daysRemainingEarlyPayment;
  final DateTime prefettoDeadline;
  final DateTime giudicePaceDeadline;
  final List<DeadlineAction> actions;

  const DeadlineInfo({
    required this.status,
    required this.title,
    required this.message,
    required this.daysSinceNotification,
    required this.daysRemainingPrefetto,
    required this.daysRemainingGiudicePace,
    required this.daysRemainingEarlyPayment,
    required this.prefettoDeadline,
    required this.giudicePaceDeadline,
    required this.actions,
  });

  /// Verifica se i termini sono scaduti
  bool get isExpired => status == DeadlineStatus.expired;

  /// Verifica se la situazione è urgente
  bool get isUrgent => status == DeadlineStatus.urgent;

  /// Verifica se c'è un avviso
  bool get hasWarning =>
      status == DeadlineStatus.warning || status == DeadlineStatus.urgent;
}
