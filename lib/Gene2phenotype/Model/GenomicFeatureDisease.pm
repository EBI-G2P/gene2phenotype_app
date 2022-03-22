=head1 LICENSE
 
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.
 
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 
=cut
package Gene2phenotype::Model::GenomicFeatureDisease; 
use Mojo::Base 'MojoX::Model';

sub fetch_by_dbID {
  my $self = shift;
  my $dbID = shift;
  my $logged_in = shift;
  my $authorised_panels = shift;
  my $user_panels = shift;

  my $registry = $self->app->defaults('registry');
  my $gfd_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
  
  my $gfd = $gfd_adaptor->fetch_by_dbID($dbID, $authorised_panels, $logged_in);
  if (!defined $gfd) {
    return undef;
  }

  my $GFD_log_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseaseLog');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');

  my @logs = ();
  if ($logged_in) {
    my $GFD_logs = $GFD_log_adaptor->fetch_all_by_GenomicFeatureDisease($gfd);
    foreach my $log (@$GFD_logs) {
      my $created = $log->created;
      my $action = $log->action;
      my $user_id = $log->user_id;  
      my $user = $user_adaptor->fetch_by_dbID($user_id);
      my $user_name = $user->username;
      push @logs, {created => $created, user => $user_name, confidence_category => '', action => $action};
    }
  }
  
  my $gfd_panels = $self->get_gfd_panels($gfd, $authorised_panels, $user_panels, $logged_in);

  my $gene_symbol = $gfd->get_GenomicFeature->gene_symbol;
  my $gene_id = $gfd->get_GenomicFeature->dbID;

  my $disease_name = $gfd->get_Disease->name; 
  my $disease_id = $gfd->get_Disease->dbID;

  my $disease_name_synonyms = $self->get_disease_name_synonyms($gfd);

  my $allelic_requirement = $gfd->allelic_requirement;
  my $allelic_requirement_list = $self->get_allelic_requirement_list($gfd, $logged_in);

  my $mutation_consequence = $gfd->mutation_consequence;
  my $mutation_consequence_list = $self->get_mutation_consequence_list($gfd, $logged_in);
  my $restricted_mutation = $gfd->restricted_mutation_set; 
  my $mutation_consequence_flag = $gfd->mutation_consequence_flag;
  my $mutation_consequence_flag_list = $self->get_mutation_consequence_flag_list($gfd, $logged_in);
  my $cross_cutting_modifier = $gfd->cross_cutting_modifier;
  my $cross_cutting_modifier_list = $self->get_cross_cutting_modifier_list($gfd, $logged_in);
  my $comments = $self->get_comments($gfd);
  my $publications = $self->get_publications($gfd);
  my $phenotypes = $self->get_phenotypes($gfd);
  my $phenotype_ids_list = $self->get_phenotype_ids_list($gfd);
  my $organs = $self->get_organs($gfd); 
  my $edit_organs = $self->get_edit_organs($gfd, $organs); 
  my $gf_statistics = $self->get_GF_statistics($gfd);

  return {
    gfd_panels => $gfd_panels,
    gene_symbol => $gene_symbol,
    gene_id => $gene_id,
    disease_name => $disease_name,
    disease_id => $disease_id,
    disease_name_synonyms => $disease_name_synonyms,
    GFD_id => $dbID,
    gfd_id => $dbID,
    allelic_requirement => $allelic_requirement,
    allelic_requirement_list => $allelic_requirement_list,
    mutation_consequence => $mutation_consequence,
    mutation_consequence_list => $mutation_consequence_list,
    mutation_consequence_flag => $mutation_consequence_flag,
    mutation_consequence_flag_list => $mutation_consequence_flag_list,
    cross_cutting_modifier => $cross_cutting_modifier, 
    cross_cutting_modifier_list => $cross_cutting_modifier_list,
    restricted_mutation => $restricted_mutation,
    comments => $comments,
    publications => $publications,
    phenotypes => $phenotypes,
    phenotype_ids_list => $phenotype_ids_list,
    organs => $organs,
    edit_organs => $edit_organs,
    logs => \@logs,
    statistics => $gf_statistics,
  };
   
}

=head2 update_allelic_requirement 
  Args        : String $email, email address of the user updating the GFD 
                Integer $GFD_id The Database id of the GFD being updated 
                $allelic_requirement Allelic requirement to be updated  
  Description: Update the allelic requirement  of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDisease::update_allelic_requirement
  Status     : Stable
=cut

sub update_allelic_requirement {
  my $self = shift;
  my $email = shift;
  my $GFD_id = shift;
  my $allelic_requirement = shift; 
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor("human", "gene2phenotype", "GenomicFeatureDisease");
  my $user_adaptor = $registry->get_adaptor("human", "gene2phenotype", "user");
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
  $GFD->allelic_requirement($allelic_requirement);
  $GFD_adaptor->update($GFD, $user);
}

=head2 update_mutation_consequence
  Args        : String $email, email address of the user updating the GFD 
                Integer $GFD_id The Database id of the GFD being updated 
                $mutation_consequence Mutation consequence to be updated  
  Description: Update the mutation consequence of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDisease::update_mutation_consequence
  Status     : Stable
=cut

sub update_mutation_consequence {
  my $self = shift;
  my $email = shift;
  my $GFD_id = shift;
  my $mutation_consequence = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor("human", "gene2phenotype", "GenomicFeatureDisease");
  my $user_adaptor = $registry->get_adaptor("human", "gene2phenotype", "user");
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
  $GFD->mutation_consequence($mutation_consequence);
  $GFD_adaptor->update($GFD, $user);

}

=head2 update_mutation_consequence_flag
  Args        : String $email, email address of the user updating the GFD 
                Integer $GFD_id The Database id of the GFD being updated 
                $mutation_consequence Mutation consequence to be updated  
  Description: Update the mutation consequence flag of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDisease::update_mutation_consequence_flag
  Status     : Stable
=cut

sub update_mutation_consequence_flag {
  my $self = shift; 
  my $email = shift; 
  my $GFD_id = shift; 
  my $mutation_consequence_flag = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor("human", "gene2phenotype", "GenomicFeatureDisease");
  my $user_adaptor = $registry->get_adaptor("human", "gene2phenotype", "user");
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
  $GFD->mutation_consequence_flag($mutation_consequence_flag);
  $GFD_adaptor->update($GFD, $user);

}

=head2 update_cross_cutting_modifier
  Args        : String $email, email address of the user updating the GFD 
                Integer $GFD_id The Database id of the GFD being updated 
                $mutation_consequence Mutation consequence to be updated  
  Description: Update the cross cutting modifier of a GenomicFeatureDisease
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDisease::update_cross_cutting_modifier
  Status     : Stable
=cut

sub update_cross_cutting_modifier { 
  my $self = shift; 
  my $email = shift;
  my $GFD_id = shift;
  my $cross_cutting_modifier = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor("human", "gene2phenotype", "GenomicFeatureDisease");
  my $user_adaptor = $registry->get_adaptor("human", "gene2phenotype", "user");
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
  $GFD->cross_cutting_modifier($cross_cutting_modifier);
  $GFD_adaptor->update($GFD, $user);
}
sub fetch_all_by_panel_restricted {
  my $self = shift;
  my $panel = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $gfds = $GFD_adaptor->fetch_all_by_panel_restricted($panel);
  my @results = ();
  foreach my $gfd (@$gfds) {
    push @results, {
      gene_symbol => $gfd->get_GenomicFeature->gene_symbol,
      disease_name => $gfd->get_Disease->name,
      GFD_id => $gfd->dbID,
    }; 
  }
  return \@results;
}

sub fetch_all_by_panel_without_publication {
  my $self = shift;
  my $panel = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $gfds = $GFD_adaptor->fetch_all_by_panel_without_publications($panel);
  my @results = ();
  foreach my $gfd (@$gfds) {
    push @results, {
      gene_symbol => $gfd->get_GenomicFeature->gene_symbol,
      disease_name => $gfd->get_Disease->name,
      GFD_id => $gfd->dbID,
    }; 
  }
  return \@results;
}

sub get_value {
  my $self = shift;
  my $type = shift;
  my $id = shift;
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $value =  $attribute_adaptor->get_value($type, $id);
  return $value;
}


sub fetch_all_by_GenomicFeature_constraints {
  my $self = shift;
  my $genomic_feature = shift;
  my $constraints = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $gfds = $GFD_adaptor->fetch_all_by_GenomicFeature_constraints($genomic_feature, $constraints);
  return $gfds;
}

sub fetch_all_by_GenomicFeature_Disease {
  my $self = shift;
  my $genomic_feature = shift;
  my $disease = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $gfds = $GFD_adaptor->fetch_all_by_GenomicFeature_Disease($genomic_feature, $disease);
  return $gfds;
}

sub fetch_by_panel_GenomicFeature_Disease {
  my $self = shift;
  my $panel = shift;
  my $gf = shift;
  my $disease = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $panel_id = $attribute_adaptor->attrib_id_for_value($panel); 
  my $gfd = $GFD_adaptor->fetch_by_GenomicFeature_Disease_panel_id($gf, $disease, $panel_id);
  return $gfd;
}

sub add {
  my $self = shift;
  my $gene_symbol = shift;
  my $disease_name = shift;
  my $allelic_requirement = shift;
  my $mutation_consequence = shift;
  my $email = shift;

  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $disease_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'Disease');
  my $disease =  $disease_adaptor->fetch_by_name($disease_name);
  my $genomic_feature_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeature');
  my $genomic_feature = $genomic_feature_adaptor->fetch_by_gene_symbol($gene_symbol);

  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');

  my $gfd =  Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
    -disease_id => $disease->dbID,
    -genomic_feature_id => $genomic_feature->dbID,
    -mutation_consequence => $mutation_consequence,
    -allelic_requirement => $allelic_requirement,
    -adaptor => $GFD_adaptor,
  );
  my $user = $user_adaptor->fetch_by_email($email);
  $gfd = $GFD_adaptor->store($gfd, $user);
  return $gfd;
}

sub delete {
  my $self = shift;
  my $email = shift;
  my $GFD_id = shift;

  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'genomicfeaturedisease');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id); 
  $GFD_adaptor->delete($GFD, $user);
}

sub get_confidence_values {
  my $self = shift;
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $confidence_categories = $attribute_adaptor->get_values_by_type('confidence_category');
  my @list = ();
  foreach my $confidence_category (sort keys %$confidence_categories) {
    my $attrib = $confidence_categories->{$confidence_category};
    push @list, [$confidence_category => $attrib];
  }
  return \@list;
}

sub get_allelic_requirements {
  my $self = shift;
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $allelic_requirements = $attribute_adaptor->get_values_by_type('allelic_requirement');
  my @AR_tmpl = ();
  foreach my $allelic_requirement (sort keys %$allelic_requirements) {
    my $attrib = $allelic_requirements->{$allelic_requirement};
    push @AR_tmpl, {
      AR_attrib_id => $attrib,
      AR_attrib_value => $allelic_requirement,
    };
  }
  return \@AR_tmpl;
}

=head2 get_cross_cutting_modifiers
  Arg [1]    : None
  Description: Used to get the cross cutting modifier and stores it in an array. 
  Returntype : Arrayref of cross_cutting_modifiers 
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDisease::edit_allelic_mutation_form 
  Status     : Stable
=cut

sub get_cross_cutting_modifiers {
  my $self = shift; 
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $cross_cutting_modifiers = $attribute_adaptor->get_values_by_type('cross_cutting_modifier');
  my @CCM_tmpl = ();
  foreach my $cross_cutting_modifier (sort keys %$cross_cutting_modifiers){
    my $attrib = $cross_cutting_modifiers->{$cross_cutting_modifier};
    push @CCM_tmpl, {
      CCM_attrib_id => $attrib, 
      CCM_attrib_value => $cross_cutting_modifier
    };
  }
  return \@CCM_tmpl;
}

sub get_mutation_consequences {
  my $self = shift;
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $mutation_consequences = $attribute_adaptor->get_values_by_type('mutation_consequence');
  my @MC_tmpl = ();
  foreach my $mutation_consequence (sort keys %$mutation_consequences) {
    my $attrib = $mutation_consequences->{$mutation_consequence};
    push @MC_tmpl, [$mutation_consequence => $attrib];
  }
  return \@MC_tmpl;
}

=head2 get_mutation_consequence_flags
  Arg [1]    : None
  Description: Used to get the mutation consequence flags and stores it in an array. 
  Returntype : Arrayref of mutation_consequence_flags 
  Exceptions : None
  Caller     : Gene2phenotype::Controller::GenomicFeatureDisease::edit_allelic_mutation_form 
  Status     : Stable
=cut

sub get_mutation_consequence_flags {
  my $self = shift; 
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $mutation_consequence_flags = $attribute_adaptor->get_values_by_type('mutation_consequence_flag');
  my @MCF_tmpl = ();
  foreach my $mutation_consequence_flag (sort keys %$mutation_consequence_flags){
    my $attrib = $mutation_consequence_flags->{$mutation_consequence_flag};
    push @MCF_tmpl, {
      MFC_attrib_id => $attrib, 
      MFC_attrib_value => $mutation_consequence_flag
    };
  }
  return \@MCF_tmpl;

}

sub _get_confidence_category_list {
  my $self = shift;
  my $selected_confidence_category = shift;
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $confidence_categories = $attribute_adaptor->get_values_by_type('confidence_category');
  my @list = ();
  foreach my $confidence_category (sort keys %$confidence_categories) { 
    my $attrib = $confidence_categories->{$confidence_category};
    my $is_selected = ($confidence_category eq $selected_confidence_category) ? 'selected' : '';
    if ($is_selected) {
      push @list, [$confidence_category => $attrib, selected => $is_selected];
    } else {
      push @list, [$confidence_category => $attrib];
    }
  }
  return \@list;
}

sub get_disease_name_synonyms {
  my $self = shift;
  my $GFD = shift;
  my @synonyms = ();
  my $gfd_disease_synonyms = $GFD->get_all_GFDDiseaseSynonyms;
  foreach my $gfd_disease_synonym (sort {$a->synonym cmp $b->synonym} @{$gfd_disease_synonyms}) {
    push @synonyms, {
      synonym => $gfd_disease_synonym->synonym,
      gfd_disease_synonym_id => $gfd_disease_synonym->dbID,
    };
  }
  return \@synonyms;
}

sub get_allelic_requirement_list {
  my $self = shift;
  my $GFD = shift;
  my @allelic_requirements = split(',', $GFD->allelic_requirement);
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $allelic_requirement_value_to_attrib = $attribute_adaptor->get_values_by_type('allelic_requirement');
  my @allelic_requirement_list = ();
  foreach my $value (sort keys %$allelic_requirement_value_to_attrib) {
    my $attrib = $allelic_requirement_value_to_attrib->{$value};
    my $checked = (grep $_ eq $value, @allelic_requirements) ? 'checked' : '';
    push @allelic_requirement_list, {
      attrib_id => $attrib,
      attrib_value => $value,
      checked => $checked,
    };
  }
  return \@allelic_requirement_list;
}

sub get_mutation_consequence_list {
  my $self = shift;
  my $GFD = shift;
  my $mutation_consequence = $GFD->mutation_consequence;
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $mutation_consequence_value_to_attrib = $attribute_adaptor->get_values_by_type('mutation_consequence');
  my @mutation_consequence_list = ();
  foreach my $value (sort keys %$mutation_consequence_value_to_attrib) {
    my $attrib = $mutation_consequence_value_to_attrib->{$value};
    my $selected = ($value eq $mutation_consequence) ? 'selected' : undef;
    if ($selected) {
      push @mutation_consequence_list, [$value => $attrib, selected => $selected];
    } else {
      push @mutation_consequence_list, [$value => $attrib];
    }
  }
  return \@mutation_consequence_list;
}

=head2 get_mutation_consequence_flag_list
  Arg [1]    : None
  Description: Used to get the mutation consequence flags and the selected flag stores it in an array. 
  Returntype : Arrayref of mutation_consequence_flags 
  Exceptions : None
  Caller     : Gene2phenotype::Model::GenomicFeatureDisease::fetch_by_dbID
  Status     : Stable
=cut

sub get_mutation_consequence_flag_list {
  my $self = shift;
  my $GFD = shift;
  my $mutation_consequence_flag = $GFD->mutation_consequence_flag;
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $mutation_consequence_flag_value_to_attrib = $attribute_adaptor->get_values_by_type('mutation_consequence_flag');
  my @mutation_consequence_flag_list = ();
  foreach my $value (sort keys %$mutation_consequence_flag_value_to_attrib) {
    my $attrib = $mutation_consequence_flag_value_to_attrib->{$value};
    my $selected = ($mutation_consequence_flag && $value eq $mutation_consequence_flag) ? 'selected' : undef;
    push @mutation_consequence_flag_list, {
        attrib_id => $attrib,
        attrib_value => $value,
        selected  => $selected,
      };
   
  } 
     
  return \@mutation_consequence_flag_list;
}

=head2 get_cross_cutting_modifier_list
  Arg [1]    : None
  Description: Used to get the cross cutting modifier list and the selected flag stores it in an array. 
  Returntype : Arrayref of cross_cutting_modifier_list 
  Exceptions : None
  Caller     : Gene2phenotype::Model::GenomicFeatureDisease::fetch_by_dbID
  Status     : Stable
=cut

sub get_cross_cutting_modifier_list {
  my $self = shift;
  my $GFD = shift;
  my @cross_cutting_modifier = split(',', $GFD->cross_cutting_modifier) if ($GFD->cross_cutting_modifier);
  my $registry = $self->app->defaults('registry');
  my $attribute_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'attribute');
  my $cross_cutting_modifier_value_to_attrib = $attribute_adaptor->get_values_by_type('cross_cutting_modifier');
  my @cross_cutting_modifier_list = ();
  foreach my $value (sort keys %$cross_cutting_modifier_value_to_attrib) {
    my $attrib = $cross_cutting_modifier_value_to_attrib->{$value};
    my $selected = (grep $_ eq $value, @cross_cutting_modifier) ? 'selected' : '';
    push @cross_cutting_modifier_list, {
      attrib_id => $attrib,
      attrib_value => $value,
      selected  => $selected,
    };
  }

  return \@cross_cutting_modifier_list;
}

sub get_publications {
  my $self = shift;
  my $gfd = shift;
  my @publications = ();

  my $registry = $self->app->defaults('registry');
  my $phenotype_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'phenotype');
  my $gfd_phenotype_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePhenotype');

  my $gfd_publications = $gfd->get_all_GFDPublications;
  foreach my $gfd_publication (sort {$a->get_Publication->title cmp $b->get_Publication->title} @$gfd_publications) {
    my $publication = $gfd_publication->get_Publication;
    my @comments = ();
    foreach my $comment (@{$gfd_publication->get_all_GFDPublicationComments;}) {
      push @comments, {
        user => $comment->get_User()->username,
        date => $comment->created,
        comment_text => $comment->comment_text,
        GFD_publication_comment_id => $comment->dbID,
        GFD_id => $gfd->dbID,
      };
    }
    my $pmid = $publication->pmid;
    my $title = $publication->title;
    my $source = $publication->source;

    $title ||= 'PMID:' . $pmid;
    $title .= " ($source)" if ($source);

    push @publications, {
      comments => \@comments,
      title => $title,
      pmid => $pmid,
      GFD_publication_id => $gfd_publication->dbID,
      GFD_id => $gfd->dbID,
    };
  }
  return \@publications;
}

sub get_comments {
  my $self = shift;
  my $GFD = shift;
  my @comments = ();
  foreach my $comment (@{$GFD->get_all_GFDComments}) {
    push @comments, {
      user => $comment->get_User()->username,
      date => $comment->created,
      comment_text => $comment->comment_text,
      is_public => $comment->is_public, 
      GFD_comment_id => $comment->dbID,
      GFD_id => $GFD->dbID,
    };
  }
  return \@comments;
}

sub get_phenotypes {
  my $self = shift;
  my $GFD = shift;

  my @phenotypes = ();
  my $GFD_phenotypes = $GFD->get_all_GFDPhenotypes;
  foreach my $GFD_phenotype ( sort { $a->get_Phenotype()->name() cmp $b->get_Phenotype()->name() } @$GFD_phenotypes) {
    my $phenotype = $GFD_phenotype->get_Phenotype;
    my $stable_id = $phenotype->stable_id;
    my $name = $phenotype->name;
    my @comments = ();
    foreach my $comment (@{$GFD_phenotype->get_all_GFDPhenotypeComments}) {
      push @comments, {
        user => $comment->get_User()->username,
        date => $comment->created,
        comment_text => $comment->comment_text,
        GFD_phenotype_comment_id => $comment->dbID,
        GFD_id => $GFD->dbID,
      };
    }

    push @phenotypes, {
      comments => \@comments,
      stable_id => $stable_id,
      name => $name,
      GFD_phenotype_id => $GFD_phenotype->dbID,
    };
  }
  my @sorted_phenotypes = sort {$a->{name} cmp $b->{name}} @phenotypes;
  return \@phenotypes;
}

sub get_organs {
  my $self = shift;
  my $GFD = shift;
  my @organ_list = ();
  my $organs = $GFD->get_all_GFDOrgans;
  foreach my $organ (@$organs) {
    my $name = $organ->get_Organ()->name;
    push @organ_list, $name;
  }
  return \@organ_list;
}

sub get_edit_organs {
  my $self = shift;
  my $GFD = shift;  
  my $organ_list = shift;
 
  my $registry = $self->app->defaults('registry');
  my $organ_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'Organ');

  my %all_organs = map {$_->name => $_->dbID} @{$organ_adaptor->fetch_all};
  my @organs = (); 
  foreach my $value (sort keys %all_organs) {
    my $id = $all_organs{$value};
    my $checked = (grep $_ eq $value, @$organ_list) ? 'checked' : '';
    push @organs, {
      organ_id => $id,
      organ_name => $value,
      checked => $checked,
    };
  }
  return \@organs;
}

sub get_GF_statistics {
  my $self = shift;
  my $GFD = shift;
  my $registry = $self->app->defaults('registry');
  my $genomic_feature_statistic_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureStatistic');
  my $GF = $GFD->get_GenomicFeature;
#  my $panel_attrib = $GFD->panel_attrib;
#  my $genomic_feature_statistics = $genomic_feature_statistic_adaptor->fetch_all_by_GenomicFeature_panel_attrib($GF, $panel_attrib);

#  if (scalar @$genomic_feature_statistics) {
#    my @statistics = ();
#    foreach (@$genomic_feature_statistics) {
#      my $clustering = ( $_->clustering) ? 'Mutatations are considered clustered.' : '';
#      push @statistics, {
#        'p-value' => $_->p_value,
#        'dataset' => $_->dataset,
#        'clustering' => $clustering,
#      }
#    }
#    return \@statistics;
#  }
  return [];
}

sub get_phenotype_ids_list {
  my $self = shift;
  my $GFD = shift;
  my @phenotype_ids = ();
  my $GFDPhenotypes = $GFD->get_all_GFDPhenotypes;
  foreach my $GFDPhenotype (@$GFDPhenotypes) {
    push @phenotype_ids, $GFDPhenotype->get_Phenotype->dbID;
  }
  return join(',', @phenotype_ids);
}

sub update_GFD_category {
  my $self = shift;
  my $email = shift;
  my $GFD_id = shift;
  my $category_attrib_id = shift;
  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);
  my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
  $GFD->confidence_category_attrib($category_attrib_id);
  $GFD_adaptor->update($GFD, $user); 
}

sub update_disease {
  my $self = shift;
  my $email = shift;
  my $GFD_id = shift;
  my $disease_id = shift;
  my $disease_name = shift;
  my $disease_mim = shift;
  
  my $registry = $self->app->defaults('registry');
  my $disease_adaptor =  $registry->get_adaptor('human', 'gene2phenotype', 'Disease');
  my $disease = $disease_adaptor->fetch_by_dbID($disease_id);
  if ($disease->name ne $disease_name || ($disease->mim && $disease->mim ne $disease_mim)) {

    my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
    my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
    my $user = $user_adaptor->fetch_by_email($email);
    $disease =  Bio::EnsEMBL::G2P::Disease->new(
      -name => $disease_name,
      -mim => $disease_mim,
      -adaptor => $disease_adaptor,
    );
    $disease = $disease_adaptor->store($disease);
    my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
    $GFD->disease_id($disease->dbID);
    $GFD_adaptor->update($GFD, $user); 
  }
}

sub update_organ_list {
  my $self = shift;
  my $email = shift;
  my $GFD_id = shift;
  my $organ_id_list = shift;

  my $registry = $self->app->defaults('registry');
  my $GFDOrgan_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseaseOrgan');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);

  $GFDOrgan_adaptor->delete_all_by_GFD_id($GFD_id);
  foreach my $organ_id (split(',', $organ_id_list)) {
    my $GFDOrgan =  Bio::EnsEMBL::G2P::GenomicFeatureDiseaseOrgan->new(
      -organ_id => $organ_id,
      -genomic_feature_disease_id => $GFD_id,
      -adaptor => $GFDOrgan_adaptor, 
    );
    $GFDOrgan_adaptor->store($GFDOrgan);
  }  
}

sub update_visibility {
  my $self = shift;
  my $email = shift;
  my $GFD_id = shift;
  my $visibility = shift;

  my $registry = $self->app->defaults('registry');
  my $GFD_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDisease');
  my $user_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'user');
  my $user = $user_adaptor->fetch_by_email($email);

  my $is_visible = $visibility eq 'authorised' ? 1 : 0;
  my $GFD = $GFD_adaptor->fetch_by_dbID($GFD_id);
  $GFD->is_visible($is_visible);
  $GFD_adaptor->update($GFD, $user); 
}

sub get_gfd_panels {
  my $self = shift;
  my $GFD = shift;
  my $authorised_panels = shift;
  my $user_panels = shift;
  my $logged_in = shift;

  my $registry = $self->app->defaults('registry');
  my $GFD_panel_adaptor = $registry->get_adaptor('human', 'gene2phenotype', 'GenomicFeatureDiseasePanel');

  my $gfd_panels = $GFD_panel_adaptor->fetch_all_by_GenomicFeatureDisease($GFD);

  my @gfd_panels = (); 

  foreach my $gfd_panel (@$gfd_panels) {
    my $panel = $gfd_panel->panel;
    # If the user is not logged in we can only show results from panels that are public
    if (!$logged_in) {
      next if (!grep {$panel eq $_} @{$authorised_panels});
    }
    my $user_can_edit = grep {$panel eq $_} @{$user_panels};
    my $confidence_category = $gfd_panel->confidence_category;
    my $is_visible = $gfd_panel->is_visible;
    my $confidence_category_list = $self->_get_confidence_category_list($confidence_category);
    push @gfd_panels, {
      GFD_id => $GFD->dbID,
      GFD_panel_id => $gfd_panel->dbID,
      panel => $panel,
      is_visible => $gfd_panel->is_visible,
      user_can_edit => $user_can_edit,
      confidence_category => $confidence_category,
      confidence_category_list => $confidence_category_list,
      clinical_review => $gfd_panel->clinical_review,
    }
  }
  return \@gfd_panels;  
}


1;
