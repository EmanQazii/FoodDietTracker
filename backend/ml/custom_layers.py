import tensorflow as tf
from tensorflow.keras import layers

class ChannelAttention(layers.Layer):

    def __init__(self, reduction_ratio=8, **kwargs):
        super(ChannelAttention, self).__init__(**kwargs)
        self.reduction_ratio = reduction_ratio

    def build(self, input_shape):

        channels = input_shape[-1]

        self.gap = layers.GlobalAveragePooling2D()

        self.dense1 = layers.Dense(
            channels // self.reduction_ratio,
            activation='relu'
        )

        self.dense2 = layers.Dense(
            channels,
            activation='sigmoid'
        )

        super(ChannelAttention, self).build(input_shape)

    def call(self, inputs):

        x = self.gap(inputs)

        x = self.dense1(x)

        x = self.dense2(x)

        x = tf.reshape(
            x,
            (-1, 1, 1, inputs.shape[-1])
        )

        return inputs * x

    def get_config(self):

        config = super(ChannelAttention, self).get_config()

        config.update({
            "reduction_ratio": self.reduction_ratio
        })

        return config