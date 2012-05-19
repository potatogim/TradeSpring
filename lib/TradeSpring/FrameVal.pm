package TradeSpring::FrameVal;
use Moose;
use methods-invoker;

use overload
    '@{}'    => \&get_offset,
    '0+'     => method { $->get },
    '""'     => method { $->get },
    'bool'   => method { $->get },
    fallback => 1;

has frame => (is => "rw", isa => "TradeSpring::Frame",
              handles => [qw(i calc date open high highest_high low lowest_low close hour last_hour is_dstart debug)],
);

has cache => (is => "ro", isa => "HashRef", default => sub { {} });

has default => (is => "ro", default => sub { undef });

has tied => (
    is => "rw",
    isa => "ArrayRef",
    lazy_build => 1
);

method _build_tied {
    my @arr = ();
    tie @arr, 'TradeSpring::FrameVal::_TiedArray', $self;
    return \@arr;
}

method set($val) {
    $->cache->{$->i} = $val;
}

method get($offset) {
    my $i = $->i - ($offset || 0);
    return $->default if $i < 0;
    $->cache->{ $i } = $->do_get unless exists $->cache->{ $i };
    $->cache->{ $i }
}

method do_get {
    $->default;
}

method get_offset {
    return $->tied;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

package TradeSpring::FrameVal::_TiedArray;

sub TIEARRAY {
    my $class    = shift;
    my $frameval = shift;
    return bless {
        frameval => $frameval,
    }, $class;
}

sub STORE {
    die "read only"
}

sub FETCH {
    my ($self, $index) = @_;
    $self->{frameval}->get($index);
}

sub FETCHSIZE {
    my ($self) = @_;
    return 10;
}

1;
