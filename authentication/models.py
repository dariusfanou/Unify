from django.db import models
from django.contrib.auth.models import AbstractUser
from authentication.managers import CustomUserManager

class User(AbstractUser):
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=150, unique=True)
    profile = models.ImageField(upload_to='images/', blank=True, null=True)
    birthday = models.DateField(null=True, blank=True)
    bio = models.TextField(null=True, blank=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    objects = CustomUserManager()

    # Système de followers/following
    following = models.ManyToManyField("self", symmetrical=False, related_name="followers", blank=True)

    def __str__(self):
        return self.username

    def follow(self, user):
        """Permet de suivre un utilisateur."""
        if user != self:
            self.following.add(user)

    def unfollow(self, user):
        """Permet de se désabonner d'un utilisateur."""
        self.following.remove(user)

    def is_following(self, user):
        """Vérifie si l'utilisateur suit un autre utilisateur."""
        return self.following.filter(id=user.id).exists()

    def get_followers(self):
        """Retourne tous les followers de l'utilisateur."""
        return self.followers.all()

    def get_following(self):
        """Retourne tous les utilisateurs suivis."""
        return self.following.all()

