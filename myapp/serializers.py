from rest_framework.serializers import ModelSerializer

from myapp.models import Post, Comment
from authentication.serializers import UserSerializer
from rest_framework import serializers

class PostSerializer(ModelSerializer):

    author = UserSerializer(read_only=True)
    comments_count = serializers.SerializerMethodField()
    likes_count = serializers.SerializerMethodField()
    has_liked = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = ['id', 'author', 'content', 'created_at', 'updated_at', 'comments_count', 'likes_count', 'has_liked']

    def get_comments_count(self, obj):
        return obj.comments.count()

    def get_likes_count(self, obj):
        return obj.total_likes()

    def get_has_liked(self, obj):
        user = self.context.get('request').user  # Récupère l'utilisateur connecté
        if user.is_authenticated:
            return obj.has_liked(user)
        return False

class LikePostSerializer(serializers.ModelSerializer):
    has_liked = serializers.SerializerMethodField()
    likes_count = serializers.IntegerField(source="total_likes", read_only=True)
    likes = UserSerializer(many=True, read_only=True)

    class Meta:
        model = Post
        fields = ["id", "likes_count", "likes", "has_liked"]

    def get_has_liked(self, obj):
        user = self.context.get('request').user  # Récupère l'utilisateur connecté
        if user.is_authenticated:
            return obj.has_liked(user)
        return False

class CommentSerializer(ModelSerializer):

    author = UserSerializer(read_only=True)

    class Meta:
        model = Comment
        fields = '__all__'
