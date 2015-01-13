#!perl

use 5.006;
use strict; use warnings;
use Games::TicTacToe;
use Test::More tests => 3;

eval { Games::TicTacToe->new(current => 'm'); };
like($@, qr/isa check for "current" failed/);

eval { Games::TicTacToe->new(board => undef); };
like($@, qr/isa check for "board" failed/);

eval { Games::TicTacToe->new(players => undef); };
like($@, qr/isa check for "players" failed/);
