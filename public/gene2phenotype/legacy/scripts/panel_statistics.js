$( document ).ready(function() {
  google.charts.load('current', {'packages':['bar']});

  if (document.getElementById('barchart_material')) {
    google.charts.setOnLoadCallback(drawChart);
  }

  function drawChart() {
    var div = document.getElementById('barchart_material');
    var input_data = JSON.parse(div.getAttribute('data'));
    var data = google.visualization.arrayToDataTable(input_data);
    var options = {
      chart: {
        title: 'Gene disease pair counts for each confidence level in each panel',
      },
      bars: 'horizontal' // Required for Material Bar Charts.
    };

    var chart = new google.charts.Bar(document.getElementById('barchart_material'));

    chart.draw(data, google.charts.Bar.convertOptions(options));

    document.getElementById('download-png').addEventListener('click', function() {
      var div = document.getElementById('barchart_material');
  
      // Use html2canvas to capture the chart
      html2canvas(div, {
        scale: 4, // Increase the scale for higher resolution
        useCORS: true
      }).then(function(canvas) {
        // Convert the canvas to a data URL
        var imgData = canvas.toDataURL('image/png');
  
        // Create a link to download the image
        var link = document.createElement('a');
        link.href = imgData;
        link.download = 'chart.png'; // Set the desired file name
        document.body.appendChild(link);
        link.click(); // Trigger the download
        document.body.removeChild(link); // Clean up
      });
    });

  }

  

});
