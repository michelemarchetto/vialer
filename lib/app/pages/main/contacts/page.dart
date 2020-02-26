import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:characters/characters.dart';
import 'package:flutter_widgets/flutter_widgets.dart';

import '../../../../domain/entities/contact.dart';
import '../../../../device/repositories/contact.dart';

import '../../../resources/theme.dart';

import '../widgets/header.dart';
import 'widgets/item.dart';
import 'widgets/letter_header.dart';

import 'controller.dart';

class ContactsPage extends View {
  final double bottomLettersPadding;

  ContactsPage({
    Key key,
    this.bottomLettersPadding = 0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactPageState();
}

class _ContactPageState extends ViewState<ContactsPage, ContactsController> {
  _ContactPageState() : super(ContactsController(DeviceContactsRepository()));

  @override
  Widget buildPage() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Header('Contacts'),
              ),
              Expanded(
                child: _AlphabetListView(
                  bottomLettersPadding: widget.bottomLettersPadding,
                  children: _mapToWidgets(controller.contacts),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _mapToWidgets(Iterable<Contact> contacts) {
    final widgets = <Widget>[];

    var currentFirstLetter;

    for (var contact in contacts) {
      var firstLetter = contact.initials.characters.firstWhere(
        (_) => true,
        orElse: () => null,
      );

      if (firstLetter != currentFirstLetter) {
        widgets.add(LetterHeader(letter: firstLetter));
        currentFirstLetter = firstLetter;
      }

      widgets.add(ContactItem(contact: contact));
    }

    return widgets;
  }
}

class _AlphabetListView extends StatefulWidget {
  final double bottomLettersPadding;
  final List<Widget> children;

  const _AlphabetListView({
    Key key,
    this.bottomLettersPadding,
    this.children,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AlphabetListViewState();
}

class _AlphabetListViewState extends State<_AlphabetListView> {
  final _controller = ItemScrollController();

  Offset _offset;
  bool _letterMarkerVisible = false;

  List<String> get _letters =>
      widget.children.whereType<LetterHeader>().map((h) => h.letter).toList();

  Size _sideLetterSize(Size parentSize) {
    final height = parentSize.height - widget.bottomLettersPadding;
    var dimension = height / _letters.length;
    dimension = max(_SideLetter.fontSize, dimension);

    return Size(dimension, dimension);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _offset = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, {@required Size parentSize}) {
    setState(() {
      _offset = details.localPosition;
      _letterMarkerVisible = true;
    });

    final letter = _letterAt(_offset, parentSize: parentSize);
    final index = widget.children
        .indexWhere((w) => w is LetterHeader && w.letter == letter);

    _controller.jumpTo(index: index);
  }

  void _onPanCancel() => setState(() {
        _letterMarkerVisible = false;
      });

  String _letterAt(Offset offset, {@required Size parentSize}) {
    final size = _sideLetterSize(parentSize);

    var index = ((_offset.dy + (size.height / 4)) / size.height).round();
    index = index.clamp(0, max(0, _letters.length - 1));

    return _letters[index];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.biggest;
        final sideLetterSize = _sideLetterSize(maxSize);

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: (d) => _onPanUpdate(d, parentSize: maxSize),
          onPanEnd: (_) => _onPanCancel(),
          onPanCancel: _onPanCancel,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              ScrollablePositionedList.builder(
                itemScrollController: _controller,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16 + sideLetterSize.width,
                ),
                itemCount: widget.children.length,
                itemBuilder: (context, index) {
                  if (widget.children.isNotEmpty) {
                    return widget.children[index];
                  } else {
                    return Container();
                  }
                },
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 86,
                    right: 16,
                    bottom: widget.bottomLettersPadding,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _letters
                        .map(
                          (letter) => _SideLetter(letter, size: sideLetterSize),
                        )
                        .toList(),
                  ),
                ),
              ),
              if (_offset != null)
                Positioned(
                  top: _offset.dy,
                  right: 48,
                  child: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.decelerate,
                    opacity: _letterMarkerVisible ? 1 : 0,
                    onEnd: () => _letterMarkerVisible = !_letterMarkerVisible,
                    child: Text(
                      _letterAt(_offset, parentSize: maxSize),
                      style: TextStyle(
                        fontSize: 32,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SideLetter extends StatelessWidget {
  static const fontSize = 10.0;

  final String letter;
  final Size size;

  const _SideLetter(
    this.letter, {
    Key key,
    @required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: Center(
        child: Text(
          letter,
          textAlign: TextAlign.center,
          textScaleFactor: 1,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: VialerColors.grey5,
          ),
        ),
      ),
    );
  }
}
