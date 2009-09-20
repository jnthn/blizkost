=head1 TITLE

blizkost.pir - A entry point

=cut

.sub 'main' :main
    .param pmc args

    load_language 'perl5'

    $P0 = compreg 'perl5'
    $P1 = $P0.'command_line'(args)
.end


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

