package Schema::Result::User;
use strict;
use warnings;
use parent('DBIx::Class');

use Digest::SHA ('sha256_hex');

__PACKAGE__->table("users");
__PACKAGE__->add_columns();
__PACKAGE__->set_primary_key("id");

sub hash_password {
    my ($self, $plain_text) = @_;

    return sha256_hex($plain_text . ($ENV{XQURSION_PW_SECRET} || '1234'));
}

sub is_password_valid {
    my ($self, $plain_text) = @_;
    return $self->password_hash eq $self->hash_password($plain_text);
}

1;
