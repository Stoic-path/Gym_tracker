# Generated manually
from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('routines', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='routine',
            name='is_public',
            field=models.BooleanField(default=False),
        ),
    ]
