/// What a learner can tell us, in the two shapes they tell it.
///
/// A message comes from someone who went looking for the form. A rating comes
/// from someone who just finished a session — one to five stars, plus an
/// optional note — which is why the session id is attached for them.
///
/// Neither shape asks the learner to classify anything: no bug / idea / other
/// on the form, no fixed list of reasons on the rating. Making someone sort
/// their own problem into our categories before they may describe it is
/// friction we get nothing for. The distinction that remains is real — the two
/// carry different fields.
library;

enum FeedbackKind {
  message('message'),
  session('session');

  const FeedbackKind(this.code);
  final String code;
}
