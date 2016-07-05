package Schema::Result::User;
use strict;
use warnings;
use parent('DBIx::Class::Core');

use Digest::SHA ('sha256_hex');

__PACKAGE__->table("users");
__PACKAGE__->add_columns("id" => { data_type => "char", is_nullable => 0, size=>64},
			 "email" => { data_type => "varchar", size => 128, is_nullable => 0},
			 "password_hash" => { data_type => "varchar", size => 64, is_nullable => 0},
			 "role" => { data_type => "char", size => 1, is_nullable => 0, default => 'u' }, # u=user, a=admin
			 "created_at" => { data_type => "datetime", is_nullable => 0 },
			 "updated_at" => { data_type => "datetime", is_nullable => 0 },			 
    );
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
