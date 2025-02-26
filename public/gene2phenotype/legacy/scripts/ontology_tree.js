$( document ).ready(function() {
  $.jstree.defaults.core.data = true;
  $.jstree.defaults.core.themes.dots = false;
  $.jstree.defaults.core.themes.icons = false;
  $.jstree.defaults.checkbox.three_state = false;

  $("input[type='search']").on("click", function () {
     $(this).select();
  });

  $("input[type='text']").on("click", function () {
     $(this).select();
  });

  var GFD_id = $('#phenotype_tree span').attr('id');

  // store list of phenotypes
  var init_ids_string = $("#update_phenotype_tree input[name=phenotype_ids]").val();
  var init_list = [];
  if (init_ids_string) {
    init_list = init_ids_string.split(',');
  }
  $('#phenotype_tree').jstree({
    
    "search" : {
      'ajax' : {
        url : '/gene2phenotype/ajax/populate_onotology_tree',
        dataType : "json",
        error : function(data, type){
          console.log(type);
        },
        success: function(data, type) {
        }, 
      }
    },

    "checkbox" : {
      "keep_selected_style" : false
    },

    "plugins" : [ "checkbox", "sort", "search" ],

    'core' : {
      'data' : {
        "url" : "/gene2phenotype/ajax/populate_onotology_tree",
        "data" : function (node) {
          return { "id" : node.id,
                   "GFD_id" : GFD_id,
                   "type" : 'expand' };
        }
      }
    },
  });
  $("#search_phenotype #search_phenotype_button").click(function() {
    var phenotype_name = $("#query_phenotype_name").val(); 
    $('#add_phenotype_info_msg').show();
    $("#phenotype_tree").jstree("search", phenotype_name);
  });

  $('#phenotype_tree').on('after_open.jstree', function(e, data) {
    $('#add_phenotype_info_msg').hide();
  });

  $('#phenotype_tree').on('select_node.jstree', function(e, data) {
    $('.edit_phenotype_list').remove();
    $( "#" + data.node.a_attr.id ).append( "<div class='edit_phenotype_list bg-success text-success'>Added to phenotype list</div>" );
    var new_id = data.node.id;
    var request = $.ajax({
      url: "/gene2phenotype/ajax/phenotype/add",
      data: "phenotype_id=" + new_id + "&GFD_id=" + GFD_id,
      success: function(data) {
       $( "#phenotype_second" ).load("/gene2phenotype/legacy/gfd?GFD_id=" + GFD_id + " #phenotype_second"); 
      }
    }); 
  });

  $('#phenotype_tree').on('deselect_node.jstree', function(e, data){
    $('.edit_phenotype_list').remove();
    $( "#" + data.node.a_attr.id ).append( "<div class='edit_phenotype_list bg-success text-success'>Deleted from phenotype list</div>" );
    var new_id = data.node.id;
    var request = $.ajax({
      url: "/gene2phenotype/ajax/phenotype/delete_from_tree",
      data: "phenotype_id=" + new_id + "&GFD_id=" + GFD_id,
      success: function(data) {
       $( "#phenotype_second" ).load("/gene2phenotype/legacy/gfd?GFD_id=" + GFD_id + " #phenotype_second"); 
      }
    }); 
  });

  function contains(a, obj) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] === obj) {
        return true;
      }
    }
    return false;
  }

  function compareArrays(arr1, arr2) {
    return $(arr1).not(arr2).length === 0 && $(arr2).not(arr1).length === 0;
  }

});
















