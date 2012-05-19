package TradeSpring::Directional;
use Moose::Role;
use Finance::GeniusTrader::Prices qw($HIGH $LOW);
use methods;
use Number::Extreme;
use Carp;


requires 'high';
requires 'low';

has direction => (is => "rw", isa => "Int");

method for_directions($code) {
    for my $dir (-1, 1) {
        my $ret = $self->with_direction($dir, $code);
        if (defined $ret) {
            return $ret;
        }
    }
}

method with_direction($dir, $code) {
    local $self->{direction} = $dir;
    $code->();
}

method mk_directional_method($pkg: $name, $long_name, $short_name, $is_function) {
    my ($long, $short) = map { ref($_) eq 'CODE' ? $_ : $pkg->can($_) }
#                                   || die "method $_ not defined for diretional method $name of $pkg" }
        ($long_name, $short_name);

    # XXX: the cache wants to be per-instance
    $pkg->meta->add_method
        ($name =>
             Moose::Meta::Method->wrap(
                 sub {
                     my ($self) = @_;
                     shift if $is_function;
                     if ($self->direction > 0) {
                         goto ($long || $self->can($long_name));
                     }
                     if ($self->direction < 0) {
                         goto ($short || $self->can($short_name));
                     }
                     croak "better requires direction being set";
                 },
                 name => $name,
                 package_name => __PACKAGE__));
}

__PACKAGE__->mk_directional_method('better' => 'high', 'low');
__PACKAGE__->mk_directional_method('worse'  => 'low',  'high');

__PACKAGE__->mk_directional_method('ne_bb'  => 'highest_high', 'lowest_low');
__PACKAGE__->mk_directional_method('ne_ww'  => 'lowest_low',  'highest_high');
__PACKAGE__->mk_directional_method('ne_best' => sub { Number::Extreme->max(@_) },
                                                sub { Number::Extreme->min(@_) }, 'function');

__PACKAGE__->mk_directional_method('ne_worst' => sub { Number::Extreme->min(@_) },
                                                 sub { Number::Extreme->max(@_) }, 'function');


use List::Util qw(max min);

__PACKAGE__->mk_directional_method('lu_best'   => 'max',  'min', 'function');
__PACKAGE__->mk_directional_method('lu_worst'  => 'min',  'max', 'function');

__PACKAGE__->mk_directional_method('bt',
                                   sub { $_[0] > $_[1] },
                                   sub { $_[0] < $_[1] }, 'function');
__PACKAGE__->mk_directional_method('wt',
                                   sub { $_[0] < $_[1] },
                                   sub { $_[0] > $_[1] }, 'function');

method we { !$self->bt(@_) }
method be { !$self->wt(@_) }

1;
