from django.db import models
from django.contrib.auth.models import AbstractUser
from authentication.managers import CustomUserManager

class User(AbstractUser):
    email = models.EmailField(unique=True)  # Champ email unique
    last_name = models.CharField(max_length=50)
    first_name = models.CharField(max_length=50)
    profile = models.ImageField(upload_to='unify-images/' ,blank=True, null=True)  # Facultatif
    username = models.CharField(max_length=150, blank=True, null=True)
    USERNAME_FIELD = 'email'  # Utiliser `email` comme identifiant principal
    REQUIRED_FIELDS = ['first_name', 'last_name']  # Champs obligatoires lors de la création de l'utilisateur

    objects = CustomUserManager()

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
    
    def save(self, *args, **kwargs):
        self.username = f'{self.first_name} {self.last_name}'
        super().save(*args, **kwargs)
