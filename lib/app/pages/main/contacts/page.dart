import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:characters/characters.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:provider/provider.dart';

import '../../../resources/localizations.dart';

import '../../../../domain/entities/brand.dart';
import '../../../../domain/entities/contact.dart';

import '../../../../domain/repositories/permission.dart';
import '../../../../domain/repositories/contact.dart';

import '../../../resources/theme.dart';

import '../../../widgets/stylized_button.dart';
import '../widgets/header.dart';
import '../widgets/conditional_placeholder.dart';
import 'widgets/item.dart';
import 'widgets/group_header.dart';

import '../../../util/conditional_capitalization.dart';

import 'controller.dart';

abstract class ContactsPageRoutes {
  static const root = '/';
  static const details = '/details';
}

class ContactsPage extends View {
  final ContactRepository _contactsRepository;
  final PermissionRepository _permissionRepository;

  final double bottomLettersPadding;

  ContactsPage(
    this._contactsRepository,
    this._permissionRepository, {
    Key key,
    this.bottomLettersPadding = 0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContactPageState(
        _contactsRepository,
        _permissionRepository,
      );
}

class _ContactPageState extends ViewState<ContactsPage, ContactsController> {
  _ContactPageState(
    ContactRepository contactRepository,
    PermissionRepository permissionRepository,
  ) : super(ContactsController(contactRepository, permissionRepository));

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
                child: Header(context.msg.main.contacts.title),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _SearchTextField(
                  onChanged: controller.onSearch,
                ),
              ),
              Expanded(
                child: ConditionalPlaceholder(
                  showPlaceholder: controller.contacts.isEmpty,
                  placeholder: controller.hasPermission
                      ? Warning(
                          icon: Icon(VialerSans.userOff),
                          title: Text(
                            context.msg.main.contacts.list.empty.title,
                          ),
                          description: Text(
                            context.msg.main.contacts.list.empty.description(
                              Provider.of<Brand>(context).appName,
                            ),
                          ),
                        )
                      : Warning(
                          icon: Icon(VialerSans.lockOn),
                          title: Text(
                            context.msg.main.contacts.list.noPermission.title,
                          ),
                          description: !controller.showSettingsDirections
                              ? Text(context.msg.main.contacts.list.noPermission
                                  .description(
                                  Provider.of<Brand>(context).appName,
                                ))
                              : Text(context.msg.main.contacts.list.noPermission
                                  .permanentDescription(
                                  Provider.of<Brand>(context).appName,
                                )),
                          children: !controller.showSettingsDirections
                              ? <Widget>[
                                  SizedBox(height: 40),
                                  StylizedButton.raised(
                                    colored: true,
                                    onPressed: controller.askPermission,
                                    child: Text(
                                      context.msg.main.contacts.list
                                          .noPermission.button
                                          .toUpperCaseIfAndroid(context),
                                    ),
                                  ),
                                ]
                              : <Widget>[],
                        ),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 200),
                    switchInCurve: Curves.decelerate,
                    switchOutCurve: Curves.decelerate.flipped,
                    child: _AlphabetListView(
                      key: ValueKey(controller.searchTerm),
                      bottomLettersPadding: widget.bottomLettersPadding,
                      children: _mapAndFilterToWidgets(controller.contacts),
                      onRefresh: () => controller.updateContacts(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _mapAndFilterToWidgets(Iterable<Contact> contacts) {
    final widgets = <String, List<ContactItem>>{};

    const numberKey = '#';
    const specialKey = '&';

    bool isAlpha(String char) =>
        char != null ? RegExp(r'\p{L}', unicode: true).hasMatch(char) : false;

    bool isNumberlike(String char) =>
        char != null ? RegExp(r'[0-9\(\+]').hasMatch(char) : false;

    final searchTerm = controller.searchTerm?.toLowerCase();
    for (var contact in contacts) {
      if (searchTerm != null &&
          !contact.name.toLowerCase().contains(searchTerm) &&
          !contact.initials.toLowerCase().contains(searchTerm) &&
          !contact.emails.any(
            (email) => email.value.toLowerCase().contains(searchTerm),
          ) &&
          !contact.phoneNumbers.any(
            (number) => number.value
                .toLowerCase()
                .replaceAll(' ', '')
                .contains(searchTerm),
          )) {
        continue;
      }

      var firstCharacter = contact.initials.characters.firstWhere(
        (_) => true,
        orElse: () => null,
      );

      final contactItem = ContactItem(contact: contact);

      // Check special groups
      if (isNumberlike(firstCharacter)) {
        widgets[numberKey] ??= [];
        widgets[numberKey].add(contactItem);
      } else if (isAlpha(firstCharacter)) {
        widgets[firstCharacter] ??= [];
        widgets[firstCharacter].add(contactItem);
      } else {
        widgets[specialKey] ??= [];
        widgets[specialKey].add(contactItem);
      }
    }

    final sortedEntries = widgets.entries.toList()
      ..sort((a, b) {
        if (a.key == numberKey) {
          return 1;
        } else if (a.key == specialKey) {
          return -1;
        } else {
          return a.key.compareTo(b.key);
        }
      });

    return sortedEntries
        .map(
          (e) => [
            GroupHeader(group: e.key),
            ...e.value
              ..sort((a, b) => a.contact.name.compareTo(b.contact.name)),
          ],
        )
        .expand((widgets) => widgets)
        .toList();
  }
}

class _AlphabetListView extends StatefulWidget {
  final double bottomLettersPadding;
  final List<Widget> children;
  final Future<void> Function() onRefresh;

  const _AlphabetListView({
    Key key,
    this.bottomLettersPadding,
    this.children,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AlphabetListViewState();
}

class _AlphabetListViewState extends State<_AlphabetListView> {
  static const _floatingLetterSize = Size(36, 36);

  final _controller = ItemScrollController();

  Offset _offset;
  bool _letterMarkerVisible = false;

  List<String> get _letters =>
      widget.children.whereType<GroupHeader>().map((h) => h.group).toList();

  Size _sideLetterSize(Size parentSize) {
    final height = parentSize.height - widget.bottomLettersPadding;
    var dimension = height / _letters.length;
    dimension = max(_SideLetter.fontSize, dimension);
    dimension = min(24, dimension);

    return Size(dimension, dimension);
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _offset = details.localPosition;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, {@required Size parentSize}) {
    setState(() {
      _offset = details.localPosition;
      _letterMarkerVisible = true;
    });

    final letter = _letterAt(_offset, parentSize: parentSize);
    final index = widget.children
        .indexWhere((w) => w is GroupHeader && w.group == letter);

    _controller.jumpTo(index: index);
  }

  void _onDragCancel() => setState(() {
        _letterMarkerVisible = false;
      });

  String _letterAt(Offset offset, {@required Size parentSize}) {
    final size = _sideLetterSize(parentSize);

    final usableParentHeight = parentSize.height - widget.bottomLettersPadding;
    final lettersFullHeight = _letters.length * size.height;

    final offsetY = _offset.dy - (usableParentHeight - lettersFullHeight) / 2;

    var index = ((offsetY - (size.height / 2)) / size.height).round();
    index = index.clamp(0, max(0, _letters.length - 1));

    return _letters[index];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxSize = constraints.biggest;
        final sideLetterSize = _sideLetterSize(maxSize);
        final showLetters = _letters.length >= 8;

        return Stack(
          fit: StackFit.expand,
          overflow: Overflow.visible,
          children: <Widget>[
            RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: ScrollablePositionedList.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemScrollController: _controller,
                itemCount: widget.children.length,
                itemBuilder: (context, index) {
                  if (widget.children.isNotEmpty) {
                    return Provider<EdgeInsets>(
                      create: (_) => EdgeInsets.only(
                        left: 16,
                        right: 16 + sideLetterSize.width,
                      ),
                      child: widget.children[index],
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
            if (showLetters)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragStart: showLetters ? _onDragStart : null,
                  onVerticalDragUpdate: showLetters
                      ? (d) => _onDragUpdate(d, parentSize: maxSize)
                      : null,
                  onVerticalDragEnd:
                      showLetters ? (_) => _onDragCancel() : null,
                  onVerticalDragCancel: showLetters ? _onDragCancel : null,
                  child: AbsorbPointer(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: widget.bottomLettersPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _letters.map(
                          (letter) {
                            return _SideLetter(letter, size: sideLetterSize);
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            if (showLetters && _offset != null)
              Positioned(
                top: _offset.dy - (_floatingLetterSize.height / 2),
                right: 48,
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.decelerate,
                  opacity: _letterMarkerVisible ? 1 : 0,
                  child: SizedBox.fromSize(
                    size: _floatingLetterSize,
                    child: Center(
                      child: Text(
                        _letterAt(_offset, parentSize: maxSize),
                        style: TextStyle(
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
            color: context.brandTheme.grey5,
          ),
        ),
      ),
    );
  }
}

class _SearchTextField extends StatefulWidget {
  final void Function(String) onChanged;

  _SearchTextField({
    Key key,
    @required this.onChanged,
  }) : super(key: key);

  @override
  _SearchTextFieldState createState() => _SearchTextFieldState();
}

class _SearchTextFieldState extends State<_SearchTextField> {
  final _searchController = TextEditingController();

  bool _canClear = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  void _handleSearch() {
    setState(() {
      _canClear = _searchController.text.isNotEmpty;
    });

    widget.onChanged(_searchController.text);
  }

  void _handleClear() {
    _searchController.clear();

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: context.brandTheme.primary,
      controller: _searchController,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.brandTheme.grey3,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          gapPadding: 0,
        ),
        prefixIcon: Icon(
          VialerSans.search,
          size: 20,
          color: context.brandTheme.grey4,
        ),
        suffixIcon: _canClear
            ? IconButton(
                onPressed: _handleClear,
                icon: Icon(
                  VialerSans.close,
                  size: 20,
                  color: context.brandTheme.grey4,
                ),
              )
            : null,
        contentPadding: EdgeInsets.all(0),
      ),
    );
  }
}
