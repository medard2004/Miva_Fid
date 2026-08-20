import 'package:flutter/material.dart';
import 'package:miva_fid/features/client/models/loyalty_card.dart';
import 'package:miva_fid/features/client/widgets/components/gradient_card_surface.dart';
import 'card_face_content.dart';

/// Face d'une carte du wallet — dégradé premium dérivé de l'identité de
/// l'établissement, profondeur et reflet via [GradientCardSurface]. Le
/// contenu (catégorie/nom/mécanique) est délégué à [CardFaceContent],
/// partagé avec l'écran de détail de carte.
///
/// Passe automatiquement en mise en page compacte sous 160px de hauteur
/// (listes, aperçus) pour ne jamais déborder — évite d'avoir à s'en
/// souvenir à chaque site d'appel ; [compact] permet de forcer l'un ou
/// l'autre mode si besoin.
class LoyaltyCardWidget extends StatelessWidget {
  final LoyaltyCard card;
  final double height;
  final bool? compact;

  const LoyaltyCardWidget({
    super.key,
    required this.card,
    this.height = 148,
    this.compact,
  });

  @override
  Widget build(BuildContext context) {
    // Texte toujours blanc — même convention que l'aperçu marchand
    // (onboarding/widgets/loyalty_card_preview.dart), qui n'adapte pas la
    // couleur du texte à la luminosité du dégradé : la carte reçue par le
    // client doit rendre exactement ce que le marchand a configuré/prévisualisé.
    const textColor = Colors.white;
    final isCompact = compact ?? height < 160;

    return GradientCardSurface(
      color: card.liningColor,
      secondaryColor: card.secondaryColor,
      gradientType: card.gradientType,
      decorationPattern: card.decorationPattern,
      height: height,
      padding:
          EdgeInsets.symmetric(horizontal: 20, vertical: isCompact ? 10 : 14),
      child:
          CardFaceContent(card: card, textColor: textColor, compact: isCompact),
    );
  }
}
