package Games::TicTacToe;

$Games::TicTacToe::VERSION = '0.11';

=head1 NAME

Games::TicTacToe - Interface to the TicTacToe (nxn) game.

=head1 VERSION

Version 0.11

=cut

use 5.006;
use Data::Dumper;
use Games::TicTacToe::Move;
use Games::TicTacToe::Board;
use Games::TicTacToe::Player;
use Games::TicTacToe::Params qw($Board $Player $Players);

use Moo;
use namespace::clean;

has 'board'   => (is => 'rw', isa => $Board);
has 'current' => (is => 'rw', isa => $Player,  default   => sub { return 'H'; });
has 'players' => (is => 'rw', isa => $Players, predicate => 1);
has 'size'    => (is => 'ro', default => sub { return 3 });
has 'winner'  => (is => 'rw', predicate => 1, clearer => 1);

=head1 DESCRIPTION

A console  based TicTacToe game to  play against the computer. A simple TicTacToe
layer supplied with the distribution in the script sub folder.  Board arranged as
nxn, where n>=3. Default size is 3,For example 5x5 would be something like below:

    +------------------------+
    |       TicTacToe        |
    +----+----+----+----+----+
    | 1  | 2  | 3  | 4  | 5  |
    +----+----+----+----+----+
    | 6  | 7  | 8  | 9  | 10 |
    +----+----+----+----+----+
    | 11 | 12 | 13 | 14 | 15 |
    +----+----+----+----+----+
    | 16 | 17 | 18 | 19 | 20 |
    +----+----+----+----+----+
    | 21 | 22 | 23 | 24 | 25 |
    +----+----+----+----+----+

=head1 SYNOPSIS

Below is the working code  for  the  TicTacToe game using the L<Games::TicTacToe>
package. The game script C<play-tictactoe> is supplied with the distribution  and
on install is available to play with.

    use strict; use warnings;
    use Games::TicTacToe;

    $SIG{'INT'} = sub { print {*STDOUT} "\n\nCaught Interrupt (^C), Aborting\n"; exit(1); };

    my ($size, $symbol);

    do {
        print {*STDOUT} "Please enter board size (type 3 if you want 3x3): ";
        $size = <STDIN>;
        chomp($size);
    } while ($size < 3);

    my $tictactoe = Games::TicTacToe->new(size => $size);

    do {
        print {*STDOUT} "Please select the symbol [X / O]: ";
        $symbol = <STDIN>;
        chomp($symbol);
    } unless (defined $symbol && ($symbol =~ /^[X|O]$/i));

    $tictactoe->addPlayer($symbol);

    my $response = 'Y';
    while (defined($response)) {
        if ($response =~ /^Y$/i) {
            print {*STDOUT} $tictactoe->getGameBoard;
            my $index = 1;
            while (!$tictactoe->isGameOver) {
                $tictactoe->play;
                if (($index % 2 == 0) && !$tictactoe->isGameOver) {
                    print {*STDOUT} $tictactoe->getGameBoard;
                }
                $index++;
            }

            $tictactoe->result;

            print {*STDOUT} "Do you wish to continue (Y/N)? ";
            $response = <STDIN>;
            chomp($response);
        }
        elsif ($response =~ /^N$/i) {
            print {*STDOUT} "Thank you.\n";
            last;
        }
        elsif ($response !~ /^[Y|N]$/i) {
            print {*STDOUT} "Invalid response, please enter (Y/N): ";
            $response = <STDIN>;
            chomp($response);
        }
    }

Once it is installed, it can be played on a terminal/command window  as below:

    $ play-tictactoe

=cut

sub BUILD {
    my ($self) = @_;

    my $size = $self->size;
    my $cell = [ map { $_ } (1..($size*$size)) ];
    $self->board(Games::TicTacToe::Board->new(cell => $cell));
}

=head1 METHODS

=head2 getGameBoard()

Returns game board for TicTacToe (3x3) by default.

=cut

sub getGameBoard {
    my ($self) = @_;

    return $self->{'board'}->as_string();
}

=head2 addPlayer($symbol)

Adds a player with the given C<$symbol>. The other symbol  would  be given to the
opposite player i.e. Computer.

=cut

sub addPlayer {
    my ($self, $symbol) = @_;

    if (($self->has_players) && (scalar(@{$self->players}) == 2)) {
        warn("WARNING: We already have 2 players to play the TicTacToe game.");
        return;
    }

    die "ERROR: Missing symbol for the player.\n" unless defined $symbol;

    $symbol = _validate_player_symbol($symbol);

    # Player 1
    push @{$self->{players}}, Games::TicTacToe::Player->new(type => 'H', symbol => $symbol);

    # Player 2
    $symbol = ($symbol eq 'X')?('O'):('X');
    push @{$self->{players}}, Games::TicTacToe::Player->new(type => 'C', symbol => $symbol);
}

=head2 getPlayers()

Returns the players information with their symbol.

=cut

sub getPlayers {
    my ($self) = @_;

    if (!($self->has_players) || scalar(@{$self->players}) == 0) {
        warn("WARNING: No player found to play the TicTacToe game.");
        return;
    }

    my $players = sprintf("+-------------+\n");
    foreach (@{$self->{players}}) {
        $players .= sprintf("|%9s: %s |\n", $_->desc, $_->symbol);
    }
    $players .= sprintf("+-------------+\n");

    return $players;
}

=head2 play()

Actually starts the game by prompting player to make a move.

=cut

sub play {
    my ($self) = @_;

    die("ERROR: Please add player before you start the game.\n")
        unless (($self->has_players) && (scalar(@{$self->players}) == 2));

    my $player = $self->_getCurrentPlayer;
    my $board  = $self->board;
    my $move   = Games::TicTacToe::Move::now($player, $board);
    $board->setCell($move, $player->symbol);
    $self->_resetCurrentPlayer() unless ($self->isGameOver);
}

=head2 isGameOver()

Returns 1 or 0 depending whether the TicTacToe is over or not.

=cut

sub isGameOver {
    my ($self) = @_;

    if (!($self->has_players) || scalar(@{$self->players}) == 0) {
        warn("WARNING: No player found to play the TicTacToe game.");
        return;
    }

    my $board = $self->board;
    foreach my $player (@{$self->players}) {
        if (Games::TicTacToe::Move::foundWinner($player, $board)) {
            $self->winner($player);
            return 1;
        }
    }

    ($board->isFull())
        ?
        (return 1)
        :
        (return 0);
}

=head2 result()

Prints the result of the game and also the game board.

=cut

sub result {
    my ($self) = @_;

    if ($self->has_winner) {
        print {*STDOUT} $self->winner->getMessage;
    }
    else {
        print {*STDOUT} "Game drawn !!!\n";
    }

    print {*STDOUT} $self->getGameBoard();

    $self->clear_winner;
    $self->board->reset;
    $self->current('H');
}

#
#
# PRIVATE METHODS

sub _validate_player_type {
    my ($player) = @_;

    while (defined($player) && ($player !~ /H|C/i)) {
        print {*STDOUT} "Please select a valid player [H - Human, C - Computer]: ";
        $player = <STDIN>;
        chomp($player);
    }

    return $player;
}

sub _validate_player_symbol {
    my ($symbol) = @_;

    while (defined($symbol) && ($symbol !~ /X|O/i)) {
        print {*STDOUT} "Please select a valid symbol [X / O]: ";
        $symbol = <STDIN>;
        chomp($symbol);
    }

    return $symbol;
}

sub _getCurrentPlayer {
    my ($self) = @_;

    ($self->{players}->[0]->{type} eq $self->{current})
    ?
    (return $self->{players}->[0])
    :
    (return $self->{players}->[1]);
}

sub _resetCurrentPlayer {
    my ($self) = @_;

    ($self->{players}->[0]->{type} eq $self->{current})
    ?
    ($self->{current} = $self->{players}->[1]->{type})
    :
    ($self->{current} = $self->{players}->[0]->{type});
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Games-TicTacToe>

=head1 BUGS

Please report any bugs / feature requests to C<bug-games-tictactoe at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-TicTacToe>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::TicTacToe

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-TicTacToe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-TicTacToe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-TicTacToe>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-TicTacToe/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2011 - 2015 Mohammad S Anwar.

This  program  is  free software;  you can redistribute it and/or modify it under
the  terms  of the the Artistic  License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Games::TicTacToe
