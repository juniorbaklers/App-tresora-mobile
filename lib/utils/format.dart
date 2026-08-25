import 'package:intl/intl.dart';

final _formatMontant = NumberFormat.decimalPattern('fr_FR');

String formatMontant(num v) => '${_formatMontant.format(v)} FCFA';

String formatDate(DateTime d) => DateFormat('dd/MM/yyyy', 'fr_FR').format(d);

String formatMoisCourt(int index) =>
    DateFormat('MMM', 'fr_FR').format(DateTime(2024, index + 1, 1));
