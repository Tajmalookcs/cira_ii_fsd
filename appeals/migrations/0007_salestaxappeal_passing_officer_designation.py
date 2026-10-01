# Recreated on 2026-10-01. The original file was lost, but the migration was
# applied to the database on 2026-09-11, so this one only restores the record.

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('appeals', '0006_incometaxappeal_officer_designation'),
    ]

    operations = [
        migrations.AddField(
            model_name='salestaxappeal',
            name='passing_officer_designation',
            field=models.CharField(blank=True, max_length=60, verbose_name='Passing Officer Designation'),
        ),
    ]
