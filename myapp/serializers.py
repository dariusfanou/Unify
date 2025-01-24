from rest_framework.serializers import ModelSerializer

from myapp.models import Post, Comment

class CommentSerializer(ModelSerializer):

    class Meta:
        model = Comment
        fields = '__all__'

class PostSerializer(ModelSerializer):

    comments = CommentSerializer(many=True)

    class Meta:
        model = Post
        fields = ['id', 'author', 'content', 'created_at', 'updated_at', 'likes', 'comments']
