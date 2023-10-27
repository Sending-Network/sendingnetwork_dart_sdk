/*
 *   Famedly Matrix SDK
 *   Copyright (C) 2019, 2020 Famedly GmbH
 *
 *   This program is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU Affero General Public License as
 *   published by the Free Software Foundation, either version 3 of the
 *   License, or (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *   GNU Affero General Public License for more details.
 *
 *   You should have received a copy of the GNU Affero General Public License
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:test/test.dart';

import 'package:sendingnetwork_dart_sdk/src/utils/sdn_id_string_extension.dart';

void main() {
  /// All Tests related to the ChatTime
  group('SDN ID String Extension', () {
    test('SDN ID String Extension', () async {
      final mxId = '@test:example.com';
      expect(mxId.isValidSDNId, true);
      expect('#test:example.com'.isValidSDNId, true);
      expect('!test:example.com'.isValidSDNId, true);
      expect('+test:example.com'.isValidSDNId, true);
      expect('\$test:example.com'.isValidSDNId, true);
      expect('\$testevent'.isValidSDNId, true);
      expect('test:example.com'.isValidSDNId, false);
      expect('@testexample.com'.isValidSDNId, false);
      expect('@:example.com'.isValidSDNId, true);
      expect('@test:'.isValidSDNId, false);
      expect(mxId.sigil, '@');
      expect('#test:example.com'.sigil, '#');
      expect('!test:example.com'.sigil, '!');
      expect('+test:example.com'.sigil, '+');
      expect('\$test:example.com'.sigil, '\$');
      expect(mxId.localpart, 'test');
      expect(mxId.domain, 'example.com');
      expect(mxId.equals('@Test:example.com'), true);
      expect(mxId.equals('@test:example.org'), false);
      expect('@user:domain:8448'.localpart, 'user');
      expect('@user:domain:8448'.domain, 'domain:8448');
    });
    test('parseIdentifierIntoParts', () {
      var res = '#alias:beep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      expect('blha'.parseIdentifierIntoParts(), null);
      res = '#alias:beep/\$event'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, '\$event');
      expect(res.queryString, null);
      res = '#alias:beep?blubb'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, 'blubb');
      res = '#alias:beep/\$event?blubb'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, '\$event');
      expect(res.queryString, 'blubb');
      res = '#/\$?:beep/\$event?blubb?b'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#/\$?:beep');
      expect(res.secondaryIdentifier, '\$event');
      expect(res.queryString, 'blubb?b');

      res = 'https://sdn.to/#/#alias:beep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      res = 'https://sdn.to/#/#🦊:beep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#🦊:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      res = 'https://sdn.to/#/%23alias%3abeep'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, null);
      res = 'https://sdn.to/#/%23alias%3abeep?boop%F0%9F%A7%A1%F0%9F%A6%8A'
          .parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#alias:beep');
      expect(res.secondaryIdentifier, null);
      expect(res.queryString, 'boop%F0%9F%A7%A1%F0%9F%A6%8A');

      res = 'https://sdn.to/#/#alias:beep?via=fox.com&via=fox.org'
          .parseIdentifierIntoParts()!;
      expect(res.via, <String>{'fox.com', 'fox.org'});

      res = 'sdn:u/her:example.org'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '@her:example.org');
      expect(res.secondaryIdentifier, null);
      expect('sdn:u/bad'.parseIdentifierIntoParts(), null);
      res = 'sdn:roomid/rid:example.org'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '!rid:example.org');
      expect(res.secondaryIdentifier, null);
      expect(res.action, null);
      res = 'sdn:r/us:example.org?action=chat'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#us:example.org');
      expect(res.secondaryIdentifier, null);
      expect(res.action, 'chat');
      res =
          'sdn:r/us:example.org/e/lol823y4bcp3qo4'.parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '#us:example.org');
      expect(res.secondaryIdentifier, '\$lol823y4bcp3qo4');
      res = 'sdn:roomid/rid:example.org?via=fox.com&via=fox.org'
          .parseIdentifierIntoParts()!;
      expect(res.primaryIdentifier, '!rid:example.org');
      expect(res.secondaryIdentifier, null);
      expect(res.via, <String>{'fox.com', 'fox.org'});
      expect('sdn:beep/boop:example.org'.parseIdentifierIntoParts(), null);
      expect('sdn:boop'.parseIdentifierIntoParts(), null);
    });
  });
}
