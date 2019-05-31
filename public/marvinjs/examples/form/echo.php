<html>
<head>
</head>
<body>
<?php if(isset($_POST['mrv'])) { ?>
<p>mrv field of the posted form</p>
<textarea cols=70 rows=20><?php echo $_POST['mrv']; ?></textarea>
<?php } else { ?>
<p>No posted form with mrv field</p>
<?php } ?>
</body>
</html>