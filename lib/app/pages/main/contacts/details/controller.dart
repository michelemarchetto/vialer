import 'package:flutter/widgets.dart';
import 'package:flutter_clean_architecture/flutter_clean_architecture.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../dialer/caller.dart';

import '../../../../../domain/repositories/contact.dart';
import '../../../../../domain/repositories/call.dart';

import '../../../../../domain/entities/contact.dart';

import 'presenter.dart';

class ContactDetailsController extends Controller with Caller {
  final ContactDetailsPresenter _presenter;

  List<Contact> contacts = [];

  ContactDetailsController(
    ContactRepository contactRepository,
    CallRepository callRepository,
  ) : _presenter = ContactDetailsPresenter(contactRepository, callRepository);

  @override
  void initController(GlobalKey<State<StatefulWidget>> key) {
    super.initController(key);

    getContacts();
  }

  void getContacts() {
    _presenter.getContacts();
  }

  void _onContactsUpdated(List<Contact> contacts) {
    this.contacts = contacts;

    refreshUI();
  }

  void mail(String destination) {
    launch('mailto:$destination');
  }

  @override
  void initListeners() {
    _presenter.contactsOnNext = _onContactsUpdated;
  }

  @override
  void executeCall(String destination) => _presenter.call(destination);
}
