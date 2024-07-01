import 'package:identity_document_detection/src/model/recognition.dart';

enum IdentityDocumentSide { front, back }

enum IdentityDocumentType { dni, card, other }

class IdentityDocument extends Recognition {
  IdentityDocument(
    super.id,
    super.label,
    super.score,
    super.location,
  );

  IdentityDocumentSide get side {
    if (label.toLowerCase().contains('front')) {
      return IdentityDocumentSide.front;
    }
    return IdentityDocumentSide.back;
  }

  IdentityDocumentType get type {
    if (label.toLowerCase().contains('dni')) {
      return IdentityDocumentType.dni;
    }
    if (label.toLowerCase().contains('card')) {
      return IdentityDocumentType.card;
    }
    return IdentityDocumentType.other;
  }
}
