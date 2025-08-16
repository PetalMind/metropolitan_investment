// Temporary file for backup - correct ending for ProductInvestorsTab

    switch (status) {
      case VotingStatus.majority:
        return 'WIĘKSZOŚĆ';
      case VotingStatus.minority:
        return 'MNIEJSZOŚĆ';
      case VotingStatus.undecided:
        return 'NIEZDECYD.';
    }
  }

  /// 📊 NOWA METODA: Formatuje kwoty w sposób kompaktowy
  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  /// 🔢 METODA: Oblicza liczbę inwestycji danego inwestora w tym produkcie
  int _getProductInvestmentCount(InvestorSummary investor) {
    return _getProductInvestments(investor).length;
  }

  /// 💰 METODA: Oblicza kapitał danego inwestora w tym produkcie
  double _getProductCapital(InvestorSummary investor) {
    final productInvestments = _getProductInvestments(investor);
    if (productInvestments.isEmpty) return 0.0;

    double totalCapital = 0.0;
    for (final investment in productInvestments) {
      // Priorytet: remainingCapital -> investmentAmount
      if (investment.remainingCapital != null &&
          investment.remainingCapital! > 0) {
        totalCapital += investment.remainingCapital!;
      } else if (investment.investmentAmount != null &&
          investment.investmentAmount! > 0) {
        totalCapital += investment.investmentAmount!;
      }
    }
    return totalCapital;
  }

  /// 🏛️ METODA: Pobiera kolor dla statusu głosowania
  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.majority:
        return AppTheme.successPrimary;
      case VotingStatus.minority:
        return AppTheme.warningPrimary;
      case VotingStatus.undecided:
        return AppTheme.textSecondary;
    }
  }

  /// 📝 METODA: Pobiera tekst dla statusu głosowania
  String _getVotingStatusText(VotingStatus status) {
    switch (status) {
      case VotingStatus.majority:
        return 'WIĘKSZOŚĆ';
      case VotingStatus.minority:
        return 'MNIEJSZOŚĆ';
      case VotingStatus.undecided:
        return 'NIEZDECYD.';
    }
  }
}
