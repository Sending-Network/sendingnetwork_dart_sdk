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

import 'package:sendingnetwork_dart_sdk/sdn.dart';

void main() {
  /// All Tests related to device keys
  group('SDN Localizations', () {
    test('SDN Localizations', () {
      expect(
          HistoryVisibility.invited
              .getLocalizedString(SDNDefaultLocalizations()),
          'From the invitation');
      expect(
          HistoryVisibility.joined
              .getLocalizedString(SDNDefaultLocalizations()),
          'From joining');
      expect(
          HistoryVisibility.shared
              .getLocalizedString(SDNDefaultLocalizations()),
          'Visible for all participants');
      expect(
          HistoryVisibility.worldReadable
              .getLocalizedString(SDNDefaultLocalizations()),
          'Visible for everyone');
      expect(GuestAccess.canJoin.getLocalizedString(SDNDefaultLocalizations()),
          'Guests can join');
      expect(
          GuestAccess.forbidden.getLocalizedString(SDNDefaultLocalizations()),
          'Guests are forbidden');
      expect(JoinRules.invite.getLocalizedString(SDNDefaultLocalizations()),
          'Invited users only');
      expect(JoinRules.public.getLocalizedString(SDNDefaultLocalizations()),
          'Anyone can join');
      expect(JoinRules.private.getLocalizedString(SDNDefaultLocalizations()),
          'private');
      expect(JoinRules.knock.getLocalizedString(SDNDefaultLocalizations()),
          'knock');
    });
  });
}
