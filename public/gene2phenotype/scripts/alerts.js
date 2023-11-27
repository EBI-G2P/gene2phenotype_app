$(document).ready(function(){
  $('.submit_form').submit(function(event){
    var email = $('.submit_form').find('input[name="email"]').val();
    var password = $('.submit_form').find('input[name="password"]').val();
    if (email == '') {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("Email field is empty. You need to enter your email address.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (password == '') {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("Password field is empty. You need to enter your password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    return 1;
  });
  $('#reset_pwd_form').submit(function(event){
    var new_pwd = $('#reset_pwd_form').find('input[name="new_password"]').val();
    var retyped_pwd = $('#reset_pwd_form').find('input[name="retyped_password"]').val();
    if (new_pwd == '') {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("New password field is empty. You need to enter a new password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (retyped_pwd == '') {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("Retype password field is empty. You need to retype your new password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (new_pwd != retyped_pwd) {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("Passwords don't match. Please ensure retyped password matches your new password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }

    return 1;
  });

  $('#update_pwd_form').submit(function(event){
    var current_pwd = $('#update_pwd_form').find('input[name="current_password"]').val();
    var new_pwd = $('#update_pwd_form').find('input[name="new_password"]').val();
    var retyped_pwd = $('#update_pwd_form').find('input[name="retyped_password"]').val();
    if (current_pwd == '') {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("Current password field is empty. You need to enter your current password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (new_pwd == '') {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("New password field is empty. You need to enter a new password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (retyped_pwd == '') {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("Retype password field is empty. You need to retype your new password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (new_pwd != retyped_pwd) {
      event.preventDefault();
      $(".alert").empty();
      $(".alert").append("Passwords don't match. Please ensure retyped password matches your new password.");
      $(".alert").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }

    return 1;
  });

  $('#add_gfd_form').submit(function(event){
    var gene_name = $('#add_gfd_form').find('input[name="gene_symbol"]').val().trim();
    var disease_name = $('#add_gfd_form').find('input[name="disease_name"]').val().trim();
    var mondo = $('#add_gfd_form').find('input[name="mondo"]').val().trim();
    var count_checked_genotypes =  $('#add_gfd_form').find('input[name="allelic_requirement_attrib_id"]:checked').length;
    var count_mutation_consequence = $('#add_gfd_form').find('input[name="mutation_consequence_attrib_id"]:checked').length;
    var publications = $('#add_gfd_form').find('input[name="publications"]').val().trim();
    
 
    if (gene_name == '') {
      event.preventDefault();
      $(".alert_add_gfd_form").empty();
      $(".alert_add_gfd_form").append("Please enter a gene name.");
      $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (disease_name == '') {
      event.preventDefault();
      $(".alert_add_gfd_form").empty();
      $(".alert_add_gfd_form").append("Please enter a disease name.");
      $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (mondo.length !== 0) {
      var isValidMondo = /^MONDO[_:][0-9]+$/.test(mondo);
      if (!isValidMondo) {
        event.preventDefault();
        $(".alert_add_gfd_form").empty();
        $(".alert_add_gfd_form").append("Please enter a valid MONDO id e.g MONDO:1234 or MONDO_1234");
        $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
        return 0;
      } else {
        $.ajax({
          url: "https://www.ebi.ac.uk/ols4/api/terms?id="+mondo,
          dataType: "json",
          type: "get",
          success: function(data) {
            if(data?.page?.totalElements === 0) {
              event.preventDefault();
              $(".alert_add_gfd_form").empty();
              $(".alert_add_gfd_form").append("Please enter a valid MONDO id e.g MONDO:1234 or MONDO_1234");
              $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
              return 0;
            }
          },
          error: function(jqXHR, textStatus, errorThrown){
            console.log(jqXHR);
            console.log(textStatus);
            console.log(errorThrown);
            event.preventDefault();
            $(".alert_add_gfd_form").empty();
            $(".alert_add_gfd_form").append("Please enter a valid MONDO id e.g MONDO:1234 or MONDO_1234");
            $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
            return 0;
          }
        });
      }
    }
    if (count_checked_genotypes == 0) {
      event.preventDefault();
      $(".alert_add_gfd_form").empty();
      $(".alert_add_gfd_form").append("Please select a genotype.");
      $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (count_mutation_consequence == 0) {
      event.preventDefault();
      $(".alert_add_gfd_form").empty();
      $(".alert_add_gfd_form").append("Please select a mutation consequence.");
      $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    if (publications.length !== 0) {
      var publications_list = publications.split(",");
      for (var i = 0; i < publications_list.length; i++) {
        var isValid = Number.isInteger(Number.parseInt(publications_list[i], 10));
        if (!isValid) {
          event.preventDefault();
          $(".alert_add_gfd_form").empty();
          $(".alert_add_gfd_form").append("Please enter a valid PMID e.g 16116424 or 16116424,9804340");
          $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
          return 0;
        } else {
          $.ajax({
            url: "https://www.ebi.ac.uk/europepmc/webservices/rest/search?query="+publications_list[i]+"&format=json",
            dataType: "json",
            type: "get",
            success: function(data) {
              if(Array.isArray(data?.resultList?.result) && data.resultList.result.length == 0) {
                event.preventDefault();
                $(".alert_add_gfd_form").empty();
                $(".alert_add_gfd_form").append("Please enter a valid PMID e.g 16116424 or 16116424,9804340");
                $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
                return 0;
              }
            },
            error: function(jqXHR, textStatus, errorThrown) {
              console.log(jqXHR);
              console.log(textStatus);
              console.log(errorThrown);
              event.preventDefault();
              $(".alert_add_gfd_form").empty();
              $(".alert_add_gfd_form").append("Please enter a valid PMID e.g 16116424 or 16116424,9804340");
              $(".alert_add_gfd_form").removeClass("alert alert-danger").addClass("alert alert-danger");
              return 0;
            }
          });
        }
      }
    }
    return 1;
  });

  $('#update_gfd_action').submit(function(event){
    var count_checked_genotypes =  $('#update_gfd_action').find('input[name="allelic_requirement_attrib_id"]:checked').length;

    if (count_checked_genotypes == 0) {
      event.preventDefault();
      $(".alert_update_gfd_action").empty();
      $(".alert_update_gfd_action").append("Please select a genotype.");
      $(".alert_update_gfd_action").removeClass("alert alert-danger").addClass("alert alert-danger");
      return 0;
    }
    return 1;
  });

});
